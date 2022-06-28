// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;
import "forge-std/console.sol";
import { EIP712 } from "./dependencies/openzeppelin/EIP712.sol";
import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "./upgradeability/Initializable.sol";
import { IBoxNFT } from "./interfaces/IBoxNFT.sol";
import { IProfileNFT } from "./interfaces/IProfileNFT.sol";
import { ISubscribeNFT } from "./interfaces/ISubscribeNFT.sol";
import { ISubscribeMiddleware } from "./interfaces/ISubscribeMiddleware.sol";
import { ICyberEngine } from "./interfaces/ICyberEngine.sol";
import { ProfileNFT } from "./ProfileNFT.sol";
import { Auth } from "./dependencies/solmate/Auth.sol";
import { RolesAuthority } from "./dependencies/solmate/RolesAuthority.sol";
import { DataTypes } from "./libraries/DataTypes.sol";
import { Constants } from "./libraries/Constants.sol";
import { BeaconProxy } from "openzeppelin-contracts/contracts/proxy/beacon/BeaconProxy.sol";
import { ERC721 } from "./dependencies/solmate/ERC721.sol";
import { CyberEngineStorage } from "./storages/CyberEngineStorage.sol";

// TODO: separate storage contract
contract CyberEngine is
    Initializable,
    Auth,
    EIP712,
    UUPSUpgradeable,
    CyberEngineStorage,
    ICyberEngine
{
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _owner,
        address _profileAddress,
        address _boxAddress,
        address _subscribeNFTBeacon,
        RolesAuthority _rolesAuthority
    ) external initializer {
        Auth.__Auth_Init(_owner, _rolesAuthority);
        EIP712.__EIP712_Init("CyberEngine", VERSION_STRING);

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

    function setSigner(address _signer) external requiresAuth {
        require(_signer != address(0), "zero address signer");
        address preSigner = signer;
        signer = _signer;

        emit SetSigner(preSigner, _signer);
    }

    function setProfileAddress(address _profileAddress) external requiresAuth {
        require(_profileAddress != address(0), "zero address profile");
        address preProfileAddr = profileAddress;
        profileAddress = _profileAddress;

        emit SetProfileAddress(preProfileAddr, _profileAddress);
    }

    function setBoxAddress(address _boxAddress) external requiresAuth {
        require(_boxAddress != address(0), "zero address box");
        address preBoxAddr = boxAddress;
        boxAddress = _boxAddress;

        emit SetBoxAddress(preBoxAddr, _boxAddress);
    }

    function setFeeByTier(DataTypes.Tier tier, uint256 amount)
        external
        requiresAuth
    {
        _setFeeByTier(tier, amount);
    }

    function setBoxGiveawayEnded(bool ended) external requiresAuth {
        bool preEnded = boxGiveawayEnded;
        boxGiveawayEnded = ended;

        emit SetBoxGiveawayEnded(preEnded, ended);
    }

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

        if (!boxGiveawayEnded) {
            IBoxNFT(boxAddress).mint(params.to);
        }

        emit Register(params.to, params.handle, params.avatar, params.metadata);

        return IProfileNFT(profileAddress).createProfile(params);
    }

    function withdraw(address to, uint256 amount) external requiresAuth {
        require(to != address(0), "withdraw to the zero address");
        uint256 balance = address(this).balance;
        require(balance >= amount, "Insufficient balance");
        payable(to).transfer(amount);

        emit Withdraw(to, amount);
    }

    function _setFeeByTier(DataTypes.Tier tier, uint256 amount) internal {
        uint256 preAmount = feeMapping[tier];
        feeMapping[tier] = amount;

        emit SetFeeByTier(tier, preAmount, amount);
    }

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

    function subscribe(uint256[] calldata profileIds, bytes[] calldata subDatas)
        external
        whenNotPaused
        returns (uint256[] memory)
    {
        return _subscribe(msg.sender, profileIds, subDatas);
    }

    function _subscribe(
        address sender,
        uint256[] calldata profileIds,
        bytes[] calldata subDatas
    ) internal returns (uint256[] memory) {
        require(profileIds.length > 0, "No profile ids provided");
        require(
            profileIds.length == subDatas.length,
            "Lenght missmatch profile ids and sub datas"
        );
        uint256[] memory result = new uint256[](profileIds.length);
        for (uint256 i = 0; i < profileIds.length; i++) {
            address subscribeNFT = _subscribeByProfileId[profileIds[i]]
                .subscribeNFT;
            address subscribeMw = _subscribeByProfileId[profileIds[i]]
                .subscribeMw;

            // lazy deploy subscribe NFT
            // TODO emit SubscribeNFT deployed event
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

    // State
    modifier whenNotPaused() {
        require(_state != DataTypes.State.Paused, "Contract is paused");
        _;
    }

    modifier whenEssensePaused() {
        require(_state != DataTypes.State.EssensePaused, "Essense is paused");
        _;
    }

    function getState() external view returns (DataTypes.State) {
        return _state;
    }

    function setState(DataTypes.State state) external requiresAuth {
        DataTypes.State preState = _state;
        _state = state;

        emit SetState(preState, state);
    }

    modifier onlyProfileOwner(uint256 profileId) {
        require(
            ERC721(profileAddress).ownerOf(profileId) == msg.sender,
            "Only profile owner"
        );
        _;
    }

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

    // Set Metadata
    function setMetadata(uint256 profileId, string calldata metadata)
        external
        onlyOwnerOrOperator(profileId)
    {
        IProfileNFT(profileAddress).setMetadata(profileId, metadata);

        emit SetMetadata(profileId, metadata);
    }

    // Set Avatar
    function setAvatar(uint256 profileId, string calldata avatar)
        external
        onlyOwnerOrOperator(profileId)
    {
        IProfileNFT(profileAddress).setAvatar(profileId, avatar);

        emit SetAvatar(profileId, avatar);
    }

    // Set Template
    function setAnimationTemplate(string calldata template)
        external
        requiresAuth
    {
        IProfileNFT(profileAddress).setAnimationTemplate(template);

        emit SetAnimationTemplate(template);
    }

    function setImageTemplate(string calldata template) external requiresAuth {
        IProfileNFT(profileAddress).setImageTemplate(template);

        emit SetImageTemplate(template);
    }

    // only owner's signature works
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
    }

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
    }

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
    }

    // upgrade
    function upgradeProfile(address newImpl) external requiresAuth {
        UUPSUpgradeable(profileAddress).upgradeTo(newImpl);
    }

    function upgradeBox(address newImpl) external requiresAuth {
        UUPSUpgradeable(boxAddress).upgradeTo(newImpl);
    }

    function getSubscribeNFTTokenURI(uint256 profileId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        return _subscribeByProfileId[profileId].tokenURI;
    }

    function getSubscribeNFT(uint256 profileId)
        external
        view
        virtual
        override
        returns (address)
    {
        return _subscribeByProfileId[profileId].subscribeNFT;
    }

    function allowSubscribeMw(address mw, bool allowed) external requiresAuth {
        bool preAllowed = _subscribeMwAllowlist[mw];
        _subscribeMwAllowlist[mw] = allowed;
        emit AllowSubscribeMw(mw, preAllowed, allowed);
    }

    function isSubscribeMwAllowed(address mw) external view returns (bool) {
        return _subscribeMwAllowlist[mw];
    }

    function getSubscribeMw(uint256 profileId) external view returns (address) {
        return _subscribeByProfileId[profileId].subscribeMw;
    }

    // TODO: withSig
    function setSubscribeMw(uint256 profileId, address mw)
        external
        onlyProfileOwner(profileId)
    {
        require(
            _subscribeMwAllowlist[mw],
            "Subscribe middleware is not allowed"
        );
        address preMw = _subscribeByProfileId[profileId].subscribeMw;
        _subscribeByProfileId[profileId].subscribeMw = mw;
        emit SetSubscribeMw(profileId, preMw, mw);
    }

    // UUPS upgradeability
    function version() external pure virtual returns (uint256) {
        return VERSION;
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
}
