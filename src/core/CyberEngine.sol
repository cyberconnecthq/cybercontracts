// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;
import "forge-std/console.sol";
import { EIP712 } from "../dependencies/openzeppelin/EIP712.sol";
import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "../upgradeability/Initializable.sol";
import { IBoxNFT } from "../interfaces/IBoxNFT.sol";
import { IProfileNFT } from "../interfaces/IProfileNFT.sol";
import { ISubscribeNFT } from "../interfaces/ISubscribeNFT.sol";
import { ISubscribeMiddleware } from "../interfaces/ISubscribeMiddleware.sol";
import { ICyberEngine } from "../interfaces/ICyberEngine.sol";
import { ProfileNFT } from "./ProfileNFT.sol";
import { BoxNFT } from "../periphery/BoxNFT.sol";
import { Auth } from "../dependencies/solmate/Auth.sol";
import { RolesAuthority } from "../dependencies/solmate/RolesAuthority.sol";
import { DataTypes } from "../libraries/DataTypes.sol";
import { Constants } from "../libraries/Constants.sol";
import { BeaconProxy } from "openzeppelin-contracts/contracts/proxy/beacon/BeaconProxy.sol";
import { ERC721 } from "../dependencies/solmate/ERC721.sol";
import { CyberEngineStorage } from "../storages/CyberEngineStorage.sol";
import { IUpgradeable } from "../interfaces/IUpgradeable.sol";

/**
 * @title CyberEngine
 * @author CyberConnect
 * @notice This is the main entry point for the CyberConnect contract.
 */
contract CyberEngine is
    Initializable,
    Auth,
    EIP712,
    UUPSUpgradeable,
    CyberEngineStorage,
    IUpgradeable,
    ICyberEngine
{
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the CyberEngine.
     *
     * @param _owner Owner to set for CyberEngine.
     * @param _profileAddress Profile address to set for CyberEngine.
     * @param _boxAddress Box Address animation url to set for CyberEngine.
     * @param _subscribeNFTBeacon Subscribe NFT beacon to set for CyberEngine.
     */
    function initialize(
        address _owner,
        address _profileAddress,
        address _boxAddress,
        address _subscribeNFTBeacon,
        RolesAuthority _rolesAuthority
    ) external initializer {
        Auth.__Auth_Init(_owner, _rolesAuthority);
        EIP712.__EIP712_Init("CyberEngine", _VERSION_STRING);

        signer = _owner;
        profileAddress = _profileAddress;
        boxAddress = _boxAddress;
        subscribeNFTBeacon = _subscribeNFTBeacon;
        _setInitialFees();

        emit Initialize(
            _owner,
            _profileAddress,
            _boxAddress,
            _subscribeNFTBeacon
        );
    }

    /**
     * @notice Sets the new signer address.
     *
     * @param _signer The signer address.
     * @dev The address can not be zero address.
     */
    function setSigner(address _signer) external requiresAuth {
        require(_signer != address(0), "zero address signer");
        address preSigner = signer;
        signer = _signer;

        emit SetSigner(preSigner, _signer);
    }

    /**
     * @notice Sets the new profile address.
     *
     * @param _profileAddress The profile address.
     * @dev The address can not be zero address.
     */
    function setProfileAddress(address _profileAddress) external requiresAuth {
        require(_profileAddress != address(0), "zero address profile");
        address preProfileAddr = profileAddress;
        profileAddress = _profileAddress;

        emit SetProfileAddress(preProfileAddr, _profileAddress);
    }

    /**
     * @notice Sets the new box address.
     *
     * @param _boxAddress The box address.
     * @dev The address can not be zero address.
     */
    function setBoxAddress(address _boxAddress) external requiresAuth {
        require(_boxAddress != address(0), "zero address box");
        address preBoxAddr = boxAddress;
        boxAddress = _boxAddress;

        emit SetBoxAddress(preBoxAddr, _boxAddress);
    }

    /**
     * @notice Sets the fee for tiers.
     *
     * @param tier The tier number.
     * @param amount The fee amount to set.
     */
    function setFeeByTier(DataTypes.Tier tier, uint256 amount)
        external
        requiresAuth
    {
        _setFeeByTier(tier, amount);
    }

    /**
     * @notice Claims a box nft for a profile.
     *
     * @param to The claimer address.
     * @param sig The EIP712 signature.
     * @return uint256 The box id.
     */
    // TODO: comment
    function claimBox(address to, DataTypes.EIP712Signature calldata sig)
        external
        payable
        returns (uint256)
    {
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._CLAIM_BOX_TYPEHASH,
                        to,
                        nonces[to]++,
                        sig.deadline
                    )
                )
            ),
            signer,
            sig
        );

        uint256 boxId = IBoxNFT(boxAddress).mint(to);
        emit ClaimBox(to, boxId);

        return boxId;
    }

    /**
     * @notice Register a new profile.
     *
     * @param params The new profile parameters.
     * @param sig The EIP712 signature.
     * @return uint256 The profile id.
     */
    function register(
        DataTypes.CreateProfileParams calldata params,
        DataTypes.EIP712Signature calldata sig
    ) external payable returns (uint256) {
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._REGISTER_TYPEHASH,
                        params.to,
                        keccak256(bytes(params.handle)),
                        keccak256(bytes(params.avatar)),
                        keccak256(bytes(params.metadata)),
                        nonces[params.to]++,
                        sig.deadline
                    )
                )
            ),
            signer,
            sig
        );

        _requireEnoughFee(params.handle, msg.value);

        uint256 profileId = IProfileNFT(profileAddress).createProfile(params);
        emit Register(
            params.to,
            profileId,
            params.handle,
            params.avatar,
            params.metadata
        );

        return profileId;
    }

    /**
     * @notice Withdraw to an address.
     *
     * @param to The receiver address.
     * @param amount The amount sent.
     */
    function withdraw(address to, uint256 amount) external requiresAuth {
        require(to != address(0), "withdraw to the zero address");
        uint256 balance = address(this).balance;
        require(balance >= amount, "Insufficient balance");
        payable(to).transfer(amount);

        emit Withdraw(to, amount);
    }

    /**
     * @notice Sets the tier fee.
     *
     * @param tier The tier number.
     * @param amount The fee amount.
     */
    function _setFeeByTier(DataTypes.Tier tier, uint256 amount) internal {
        uint256 preAmount = feeMapping[tier];
        feeMapping[tier] = amount;

        emit SetFeeByTier(tier, preAmount, amount);
    }

    /**
     * @notice Sets the initial tier fee.
     */
    function _setInitialFees() internal {
        _setFeeByTier(DataTypes.Tier.Tier0, Constants._INITIAL_FEE_TIER0);
        _setFeeByTier(DataTypes.Tier.Tier1, Constants._INITIAL_FEE_TIER1);
        _setFeeByTier(DataTypes.Tier.Tier2, Constants._INITIAL_FEE_TIER2);
        _setFeeByTier(DataTypes.Tier.Tier3, Constants._INITIAL_FEE_TIER3);
        _setFeeByTier(DataTypes.Tier.Tier4, Constants._INITIAL_FEE_TIER4);
        _setFeeByTier(DataTypes.Tier.Tier5, Constants._INITIAL_FEE_TIER5);
    }

    function _requiresExpectedSigner(
        bytes32 digest,
        address expectedSigner,
        DataTypes.EIP712Signature calldata sig
    ) internal view {
        require(sig.deadline >= block.timestamp, "Deadline expired");
        address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);
        require(recoveredAddress == expectedSigner, "Invalid signature");
    }

    /**
     * @notice Checks if the fee is enough.
     *
     * @param handle The profile handle.
     * @param amount The msg value.
     */
    function _requireEnoughFee(string calldata handle, uint256 amount)
        internal
        view
    {
        bytes memory byteHandle = bytes(handle);
        uint256 fee = feeMapping[DataTypes.Tier.Tier5];

        require(byteHandle.length >= 1, "Invalid handle length");
        if (byteHandle.length < 6) {
            fee = feeMapping[DataTypes.Tier(byteHandle.length - 1)];
        }
        require(amount >= fee, "Insufficient fee");
    }

    /**
     * @notice Subscribe to an address(es) with a signature.
     *
     * @param sender The sender address.
     * @param profileIds The profile ids to subscribed to.
     * @param subDatas The subscription data set.
     * @param sig The EIP712 signature.
     * @dev the function requires the stated to be not paused.
     * @return memory The subscription nft ids.
     */
    function subscribeWithSig(
        uint256[] calldata profileIds,
        bytes[] calldata subDatas,
        address sender,
        DataTypes.EIP712Signature calldata sig
    ) external whenNotPaused returns (uint256[] memory) {
        uint256 length = subDatas.length;
        bytes32[] memory hashes = new bytes32[](length);
        for (uint256 i = 0; i < length; ) {
            hashes[i] = keccak256(subDatas[i]);
            unchecked {
                ++i;
            }
        }

        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._SUBSCRIBE_TYPEHASH,
                        keccak256(abi.encodePacked(profileIds)),
                        keccak256(abi.encodePacked(hashes)),
                        nonces[sender]++,
                        sig.deadline
                    )
                )
            ),
            sender,
            sig
        );
        return _subscribe(sender, profileIds, subDatas);
    }

    /**
     * @notice The subscription functionality.
     *
     * @param profileIds The profile ids to subscribed to.
     * @param subDatas The subscription data set.
     * @return memory The subscription nft ids.
     * @dev the function requires the stated to be not paused.
     */
    function subscribe(uint256[] calldata profileIds, bytes[] calldata subDatas)
        external
        whenNotPaused
        returns (uint256[] memory)
    {
        return _subscribe(msg.sender, profileIds, subDatas);
    }

    /**
     * @notice The subscription functionality.
     *
     * @param sender The sender address.
     * @param profileIds The profile ids to subscribed to.
     * @param subDatas The subscription data set.
     * @return memory The subscription nft ids.
     */
    function _subscribe(
        address sender,
        uint256[] calldata profileIds,
        bytes[] calldata subDatas
    ) internal returns (uint256[] memory) {
        require(profileIds.length > 0, "No profile ids provided");
        require(
            profileIds.length == subDatas.length,
            "Length missmatch ids & sub datas"
        );
        uint256[] memory result = new uint256[](profileIds.length);
        for (uint256 i = 0; i < profileIds.length; i++) {
            address subscribeNFT = _subscribeByProfileId[profileIds[i]]
                .subscribeNFT;
            address subscribeMw = _subscribeByProfileId[profileIds[i]]
                .subscribeMw;

            // lazy deploy subscribe NFT
            if (subscribeNFT == address(0)) {
                bytes memory initData = abi.encodeWithSelector(
                    ISubscribeNFT.initialize.selector,
                    profileIds[i]
                );
                subscribeNFT = address(
                    new BeaconProxy(subscribeNFTBeacon, initData)
                );
                _subscribeByProfileId[profileIds[i]]
                    .subscribeNFT = subscribeNFT;
                emit DeploySubscribeNFT(profileIds[i], subscribeNFT);
            }
            // run middleware before subscribe
            if (subscribeMw != address(0)) {
                ISubscribeMiddleware(subscribeMw).preProcess(
                    profileIds[i],
                    sender,
                    subscribeNFT,
                    subDatas[i]
                );
            }
            result[i] = ISubscribeNFT(subscribeNFT).mint(sender);
            if (subscribeMw != address(0)) {
                ISubscribeMiddleware(subscribeMw).postProcess(
                    profileIds[i],
                    sender,
                    subscribeNFT,
                    subDatas[i]
                );
            }
        }

        emit Subscribe(sender, profileIds, subDatas);
        return result;
    }

    /**
     * @notice Checks that the state is not paused.
     */
    modifier whenNotPaused() {
        require(_state != DataTypes.State.Paused, "Contract is paused");
        _;
    }

    // TODO: maybe remove essence
    modifier whenEssensePaused() {
        require(_state != DataTypes.State.EssensePaused, "Essense is paused");
        _;
    }

    /**
     * @notice Gets the contract state.
     *
     * @return State The contract state.
     */
    function getState() external view returns (DataTypes.State) {
        return _state;
    }

    /**
     * @notice Sets the contract state.
     *
     * @param state The new state to set.
     */
    function setState(DataTypes.State state) external requiresAuth {
        DataTypes.State preState = _state;
        _state = state;

        emit SetState(preState, state);
    }

    /**
     * @notice Checks that the profile owner is the sender address.
     */
    modifier onlyProfileOwner(uint256 profileId) {
        require(
            ERC721(profileAddress).ownerOf(profileId) == msg.sender,
            "Only profile owner"
        );
        _;
    }

    /**
     * @notice Checks that the profile owner or operator is the sender address.
     */
    modifier onlyOwnerOrOperator(uint256 profileId) {
        require(
            ERC721(profileAddress).ownerOf(profileId) == msg.sender ||
                IProfileNFT(profileAddress).getOperatorApproval(
                    profileId,
                    msg.sender
                ),
            "Only profile owner or operator"
        );
        _;
    }

    /**
     * @notice Sets the Profile NFT metadata as IPFS hash.
     *
     * @param profileId The profile ID.
     * @param metadata The new metadata to set.
     */
    function setMetadata(uint256 profileId, string calldata metadata)
        external
        onlyOwnerOrOperator(profileId)
    {
        IProfileNFT(profileAddress).setMetadata(profileId, metadata);

        emit SetMetadata(profileId, metadata);
    }

    /**
     * @notice Sets the Profile NFT avatar.
     *
     * @param profileId The profile ID.
     * @param avatar The new avatar url to set.
     */
    function setAvatar(uint256 profileId, string calldata avatar)
        external
        onlyOwnerOrOperator(profileId)
    {
        IProfileNFT(profileAddress).setAvatar(profileId, avatar);

        emit SetAvatar(profileId, avatar);
    }

    /**
     * @notice Sets the Profile NFT animation url.
     *
     * @param template The new template url to set.
     */
    function setAnimationTemplate(string calldata template)
        external
        requiresAuth
    {
        IProfileNFT(profileAddress).setAnimationTemplate(template);

        emit SetAnimationTemplate(template);
    }

    /**
     * @notice Sets the Profile NFT image.
     *
     * @param template The new template url to set.
     */
    function setImageTemplate(string calldata template) external requiresAuth {
        IProfileNFT(profileAddress).setImageTemplate(template);

        emit SetImageTemplate(template);
    }

    /**
     * @notice Sets the profile metadata with a signture.
     *
     * @param profileId The profile ID.
     * @param metadata The new metadata to be set.
     * @param sig The EIP712 signature.
     * @dev Only owner's signature works.
     */
    function setMetadataWithSig(
        uint256 profileId,
        string calldata metadata,
        DataTypes.EIP712Signature calldata sig
    ) external {
        address owner = ERC721(profileAddress).ownerOf(profileId);
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._SET_METADATA_TYPEHASH,
                        profileId,
                        keccak256(bytes(metadata)),
                        nonces[owner]++,
                        sig.deadline
                    )
                )
            ),
            owner,
            sig
        );
        IProfileNFT(profileAddress).setMetadata(profileId, metadata);

        emit SetMetadata(profileId, metadata);
    }

    /**
     * @notice Sets the operator approval.
     *
     * @param profileId The profile ID.
     * @param operator The operator address.
     * @param approved The new state of the approval.
     */
    function setOperatorApproval(
        uint256 profileId,
        address operator,
        bool approved
    ) external onlyProfileOwner(profileId) {
        IProfileNFT(profileAddress).setOperatorApproval(
            profileId,
            operator,
            approved
        );

        emit SetOperatorApproval(profileId, operator, approved);
    }

    /**
     * @notice Sets the operator approval with a signature.
     *
     * @param profileId The profile ID.
     * @param operator The operator address.
     * @param approved The new state of the approval.
     * @param sig The EIP712 signature.
     */
    function setOperatorApprovalWithSig(
        uint256 profileId,
        address operator,
        bool approved,
        DataTypes.EIP712Signature calldata sig
    ) external {
        address owner = ERC721(profileAddress).ownerOf(profileId);
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._SET_OPERATOR_APPROVAL_TYPEHASH,
                        profileId,
                        operator,
                        approved,
                        nonces[owner]++,
                        sig.deadline
                    )
                )
            ),
            owner,
            sig
        );
        IProfileNFT(profileAddress).setOperatorApproval(
            profileId,
            operator,
            approved
        );
        emit SetOperatorApproval(profileId, operator, approved);
    }

    // upgrade
    function upgradeProfile(address newImpl) external requiresAuth {
        UUPSUpgradeable(profileAddress).upgradeTo(newImpl);
    }

    function upgradeBox(address newImpl) external requiresAuth {
        UUPSUpgradeable(boxAddress).upgradeTo(newImpl);
    }

    // pause
    function pauseProfile(bool toPause) external requiresAuth {
        ProfileNFT(profileAddress).pause(toPause);
    }

    function pauseBox(bool toPause) external requiresAuth {
        BoxNFT(boxAddress).pause(toPause);
    }

    /// @inheritdoc ICyberEngine
    function getSubscribeNFTTokenURI(uint256 profileId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        return _subscribeByProfileId[profileId].tokenURI;
    }

    /// @inheritdoc ICyberEngine
    function getSubscribeNFT(uint256 profileId)
        external
        view
        virtual
        override
        returns (address)
    {
        return _subscribeByProfileId[profileId].subscribeNFT;
    }

    /**
     * @notice Allows the subscriber middleware.
     *
     * @param mw The middleware address.
     * @param allowed The allowance state.
     */
    function allowSubscribeMw(address mw, bool allowed) external requiresAuth {
        bool preAllowed = _subscribeMwAllowlist[mw];
        _subscribeMwAllowlist[mw] = allowed;
        emit AllowSubscribeMw(mw, preAllowed, allowed);
    }

    /**
     * @notice Checks if the subscriber middleware is allowed.
     *
     * @param mw The middleware address.
     * @return bool The allowance state.
     */
    function isSubscribeMwAllowed(address mw) external view returns (bool) {
        return _subscribeMwAllowlist[mw];
    }

    /**
     * @notice Gets a profile subscribe middleware address.
     *
     * @param profileId The profile id.
     * @return address The middleware address.
     */
    function getSubscribeMw(uint256 profileId) external view returns (address) {
        return _subscribeByProfileId[profileId].subscribeMw;
    }

    // TODO: withSig
    function setSubscribeMw(uint256 profileId, address mw)
        external
        onlyProfileOwner(profileId)
    {
        require(_subscribeMwAllowlist[mw], "Subscribe middleware not allowed");
        address preMw = _subscribeByProfileId[profileId].subscribeMw;
        _subscribeByProfileId[profileId].subscribeMw = mw;
        emit SetSubscribeMw(profileId, preMw, mw);
    }

    // UUPS upgradeability
    function version() external pure virtual override returns (uint256) {
        return _VERSION;
    }

    // UUPS upgradeability
    function _authorizeUpgrade(address) internal override canUpgrade {}

    // UUPS upgradeability
    modifier canUpgrade() {
        require(
            isAuthorized(msg.sender, Constants._AUTHORIZE_UPGRADE),
            "UNAUTHORIZED"
        );

        _;
    }

    //
}
