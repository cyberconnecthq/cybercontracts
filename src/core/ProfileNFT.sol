// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IProfileNFT } from "../interfaces/IProfileNFT.sol";
import { IUpgradeable } from "../interfaces/IUpgradeable.sol";
import { ICyberEngine } from "../interfaces/ICyberEngine.sol";
import { CyberNFTBase } from "../base/CyberNFTBase.sol";
import { Constants } from "../libraries/Constants.sol";
import { DataTypes } from "../libraries/DataTypes.sol";
import { LibString } from "../libraries/LibString.sol";
import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { ProfileNFTStorage } from "../storages/ProfileNFTStorage.sol";
import { Pausable } from "../dependencies/openzeppelin/Pausable.sol";
import { IProfileNFTDescriptor } from "../interfaces/IProfileNFTDescriptor.sol";
import { Auth } from "../dependencies/solmate/Auth.sol";
import { ISubscribeNFT } from "../interfaces/ISubscribeNFT.sol";
import { IEssenceNFT } from "../interfaces/IEssenceNFT.sol";
import { BeaconProxy } from "openzeppelin-contracts/contracts/proxy/beacon/BeaconProxy.sol";
import { ISubscribeMiddleware } from "../interfaces/ISubscribeMiddleware.sol";
import { IProfileMiddleware } from "../interfaces/IProfileMiddleware.sol";
import { IEssenceMiddleware } from "../interfaces/IEssenceMiddleware.sol";
import { IProfileDeployer } from "../interfaces/IProfileDeployer.sol";
import { RolesAuthority } from "../dependencies/solmate/RolesAuthority.sol";
import { ReentrancyGuard } from "../dependencies/openzeppelin/ReentrancyGuard.sol";

/**
 * @title Profile NFT
 * @author CyberConnect
 * @notice This contract is used to create a profile NFT.
 */

contract ProfileNFT is
    Pausable,
    ReentrancyGuard,
    Auth,
    CyberNFTBase,
    UUPSUpgradeable,
    ProfileNFTStorage,
    IUpgradeable,
    IProfileNFT
{
    /* solhint-disable var-name-mixedcase */

    address public immutable SUBSCRIBE_BEACON;
    address public immutable ESSENCE_BEACON;
    address public immutable ENGINE;

    /* solhint-enable var-name-mixedcase */

    constructor() {
        ENGINE = msg.sender;
        (, , address subBeacon, address essenceBeacon) = IProfileDeployer(
            msg.sender
        ).parameters();
        SUBSCRIBE_BEACON = subBeacon;
        ESSENCE_BEACON = essenceBeacon;
        _disableInitializers();
    }

    /**
     * @notice Initializes the Profile NFT.
     *
     * @param name Name to set for the Profile NFT.
     * @param symbol Symbol to set for the Profile NFT.
     * @param nftDescriptor The profile NFT descriptor address to set for the Profile NFT.
     */
    function initialize(
        address _owner,
        string calldata name,
        string calldata symbol,
        address nftDescriptor,
        RolesAuthority _rolesAuthority
    ) external initializer {
        require(nftDescriptor != address(0), "ZERO_ADDRESS");
        CyberNFTBase._initialize(name, symbol);
        Auth.__Auth_Init(_owner, _rolesAuthority);
        ReentrancyGuard.__ReentrancyGuard_init();
        _nftDescriptor = nftDescriptor;

        emit Initialize(_owner);
        // start with paused
        _pause();
    }

    /// @inheritdoc IProfileNFT
    function createProfile(
        DataTypes.CreateProfileParams calldata params,
        bytes calldata data
    ) external payable override nonReentrant returns (uint256) {
        address profileMw = ICyberEngine(ENGINE)
            .getNamespaceData(address(this))
            .profileMw;

        if (profileMw != address(0)) {
            IProfileMiddleware(profileMw).preProcess{ value: msg.value }(
                params,
                data
            );
        }

        uint256 id = _createProfile(params);
        if (profileMw != address(0)) {
            IProfileMiddleware(profileMw).postProcess(params, data);
        }
        return id;
    }

    function _createProfile(DataTypes.CreateProfileParams calldata params)
        internal
        returns (uint256)
    {
        bytes32 handleHash = keccak256(bytes(params.handle));
        require(!_exists(_profileIdByHandleHash[handleHash]), "HANDLE_TAKEN");

        uint256 id = _mint(params.to);

        _profileById[_totalCount].handle = params.handle;
        _profileById[_totalCount].avatar = params.avatar;

        _profileIdByHandleHash[handleHash] = _totalCount;
        _metadataById[_totalCount] = params.metadata;
        emit CreateProfile(
            params.to,
            id,
            params.handle,
            params.avatar,
            params.metadata
        );

        if (_addressToPrimaryProfile[params.to] == 0) {
            _setPrimaryProfile(params.to, id);
            emit SetPrimaryProfile(params.to, id);
        }
        return id;
    }

    /// @inheritdoc IProfileNFT
    function getHandleByProfileId(uint256 profileId)
        external
        view
        override
        returns (string memory)
    {
        _requireMinted(profileId);
        return _profileById[profileId].handle;
    }

    /// @inheritdoc IProfileNFT
    function getProfileIdByHandle(string calldata handle)
        external
        view
        override
        returns (uint256)
    {
        bytes32 handleHash = keccak256(bytes(handle));
        return _profileIdByHandleHash[handleHash];
    }

    /**
     * @notice Generates the metadata json object.
     *
     * @param tokenId The profile NFT token ID.
     * @return string The metadata json object.
     * @dev It requires the tokenId to be already minted.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        string memory handle = _profileById[tokenId].handle;
        address subscribeNFT = _subscribeByProfileId[tokenId].subscribeNFT;
        uint256 subscribers;
        if (subscribeNFT == address(0)) {
            subscribers = 0;
        } else {
            // TODO: maybe replace with interface to save gas
            subscribers = CyberNFTBase(subscribeNFT).totalSupply();
        }

        return
            IProfileNFTDescriptor(_nftDescriptor).tokenURI(
                DataTypes.ConstructTokenURIParams({
                    tokenId: tokenId,
                    handle: handle,
                    subscribers: subscribers
                })
            );
    }

    /// @inheritdoc IProfileNFT
    function getNFTDescriptor()
        external
        view
        override
        returns (address)
    {
        return _nftDescriptor;
    }

    /// @inheritdoc IProfileNFT
    function getOperatorApproval(uint256 profileId, address operator)
        public
        view
        returns (bool)
    {
        _requireMinted(profileId);
        return _operatorApproval[profileId][operator];
    }

    function _setOperatorApproval(
        uint256 profileId,
        address operator,
        bool approved
    ) internal {
        require(operator != address(0), "ZERO_ADDRESS");
        bool prev = _operatorApproval[profileId][operator];
        _operatorApproval[profileId][operator] = approved;
        emit SetOperatorApproval(profileId, operator, prev, approved);
    }

    /// @inheritdoc IProfileNFT
    function setOperatorApproval(
        uint256 profileId,
        address operator,
        bool approved
    ) external override onlyProfileOwner(profileId) {
        _setOperatorApproval(profileId, operator, approved);
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
        address owner = ownerOf(profileId);
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
        _setOperatorApproval(profileId, operator, approved);
    }

    function _setMetadata(uint256 profileId, string calldata metadata)
        internal
    {
        require(
            bytes(metadata).length <= Constants._MAX_URI_LENGTH,
            "METADATA_INVALID_LENGTH"
        );
        _metadataById[profileId] = metadata;
        emit SetMetadata(profileId, metadata);
    }

    /// @inheritdoc IProfileNFT
    function setMetadata(uint256 profileId, string calldata metadata)
        external
        override
        onlyProfileOwnerOrOperator(profileId)
    {
        _setMetadata(profileId, metadata);
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
        address owner = ownerOf(profileId);
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
        _setMetadata(profileId, metadata);
    }

    /// @inheritdoc IProfileNFT
    function getMetadata(uint256 profileId)
        external
        view
        override
        returns (string memory)
    {
        _requireMinted(profileId);
        return _metadataById[profileId];
    }

    /// @inheritdoc IProfileNFT
    function getAvatar(uint256 profileId)
        external
        view
        override
        returns (string memory)
    {
        _requireMinted(profileId);
        return _profileById[profileId].avatar;
    }

    /// @inheritdoc IProfileNFT
    function setNFTDescriptor(address descriptor)
        external
        override
        requiresAuth
    {
        _nftDescriptor = descriptor;
        emit SetNFTDescriptor(descriptor);
    }

    function setAnimationTemplate(string calldata template)
        external
        requiresAuth
    {
        IProfileNFTDescriptor(_nftDescriptor).setAnimationTemplate(
            template
        );

        emit SetAnimationTemplate(template);
    }

    /// @inheritdoc IProfileNFT
    function setAvatar(uint256 profileId, string calldata avatar)
        external
        override
        onlyProfileOwnerOrOperator(profileId)
    {
        require(
            bytes(avatar).length <= Constants._MAX_URI_LENGTH,
            "AVATAR_INVALID_LENGTH"
        );
        _profileById[profileId].avatar = avatar;
        emit SetAvatar(profileId, avatar);
    }

    // TODO: UUPS base contracts for functions
    // TODO: write a test for upgrade profile nft
    function version() external pure virtual override returns (uint256) {
        return _VERSION;
    }

    // UUPS upgradeability
    function _authorizeUpgrade(address) internal override canUpgrade {}

    /**
     * @notice Checks if the sender is authorized to upgrade the contract.
     */
    modifier canUpgrade() {
        require(
            isAuthorized(msg.sender, Constants._AUTHORIZE_UPGRADE),
            "UNAUTHORIZED"
        );

        _;
    }

    /**
     * @notice Changes the pause state of the profile nft.
     *
     * @param toPause The pause state.
     */
    function pause(bool toPause) external requiresAuth {
        if (toPause) {
            super._pause();
        } else {
            super._unpause();
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override whenNotPaused {
        super.transferFrom(from, to, id);
    }

    /// @inheritdoc IProfileNFT
    function setPrimaryProfile(uint256 profileId)
        external
        override
        onlyProfileOwner(profileId)
    {
        _requireMinted(profileId);
        _setPrimaryProfile(msg.sender, profileId);
        emit SetPrimaryProfile(msg.sender, profileId);
    }

    function _setPrimaryProfile(address user, uint256 profileId) internal {
        _addressToPrimaryProfile[user] = profileId;
    }

    /// @inheritdoc IProfileNFT
    function getPrimaryProfile(address user)
        external
        view
        override
        returns (uint256)
    {
        return _addressToPrimaryProfile[user];
    }

    /**
     * @notice Checks that the profile owner is the sender address.
     */
    modifier onlyProfileOwner(uint256 profileId) {
        require(ownerOf(profileId) == msg.sender, "ONLY_PROFILE_OWNER");
        _;
    }

    /**
     * @notice Checks that the profile owner or operator is the sender address.
     */
    modifier onlyProfileOwnerOrOperator(uint256 profileId) {
        require(
            ownerOf(profileId) == msg.sender ||
                getOperatorApproval(profileId, msg.sender),
            "ONLY_PROFILE_OWNER_OR_OPERATOR"
        );
        _;
    }

    function getSubscribeNFT(uint256 profileId)
        external
        view
        override
        returns (address)
    {
        return _subscribeByProfileId[profileId].subscribeNFT;
    }

    function getSubscribeNFTTokenURI(uint256 profileId)
        external
        view
        override
        returns (string memory)
    {
        return _subscribeByProfileId[profileId].tokenURI;
    }

    function getEssenceNFT(uint256 profileId, uint256 essenceId)
        external
        view
        override
        returns (address)
    {
        return _essenceByIdByProfileId[profileId][essenceId].essenceNFT;
    }

    function getEssenceNFTTokenURI(uint256 profileId, uint256 essenceId)
        external
        view
        override
        returns (string memory)
    {
        return _essenceByIdByProfileId[profileId][essenceId].tokenURI;
    }

    /**
     * @notice The subscription functionality.
     *
     * @param sender The sender address.
     * @param profileIds The profile ids to subscribed to.
     * @param preDatas The subscription data used in pre process.
     * @param postDatas The subscription data used in post process.
     * @return result The subscription nft ids.
     */
    function _subscribe(
        address sender,
        uint256[] calldata profileIds,
        bytes[] calldata preDatas,
        bytes[] calldata postDatas
    ) internal returns (uint256[] memory result) {
        require(profileIds.length > 0, "NO_PROFILE_IDS");
        require(
            profileIds.length == preDatas.length &&
                preDatas.length == postDatas.length,
            "LENGTH_MISMATCH"
        );
        result = new uint256[](profileIds.length);
        for (uint256 i = 0; i < profileIds.length; i++) {
            _requireMinted(profileIds[i]);
            address subscribeNFT = _subscribeByProfileId[profileIds[i]]
                .subscribeNFT;
            address subscribeMw = _subscribeByProfileId[profileIds[i]]
                .subscribeMw;
            // lazy deploy subscribe NFT
            if (subscribeNFT == address(0)) {
                subscribeNFT = _deploySubscribeNFT(profileIds[i]);
            }
            // run middleware before subscribe
            if (subscribeMw != address(0)) {
                ISubscribeMiddleware(subscribeMw).preProcess(
                    profileIds[i],
                    sender,
                    subscribeNFT,
                    preDatas[i]
                );
            }
            result[i] = ISubscribeNFT(subscribeNFT).mint(sender);
            if (subscribeMw != address(0)) {
                ISubscribeMiddleware(subscribeMw).postProcess(
                    profileIds[i],
                    sender,
                    subscribeNFT,
                    postDatas[i]
                );
            }
        }

        emit Subscribe(sender, profileIds, preDatas, postDatas);
        return result;
    }

    function _deploySubscribeNFT(uint256 profileId) internal returns (address) {
        address subscribeNFT = address(
            new BeaconProxy(
                SUBSCRIBE_BEACON,
                abi.encodeWithSelector(
                    ISubscribeNFT.initialize.selector,
                    profileId,
                    string(
                        abi.encodePacked(
                            _profileById[profileId].handle,
                            Constants._SUBSCRIBE_NFT_NAME_SUFFIX
                        )
                    ),
                    string(
                        abi.encodePacked(
                            LibString.toUpper(_profileById[profileId].handle),
                            Constants._SUBSCRIBE_NFT_SYMBOL_SUFFIX
                        )
                    )
                )
            )
        );
        _subscribeByProfileId[profileId].subscribeNFT = subscribeNFT;
        emit DeploySubscribeNFT(profileId, subscribeNFT);
        return subscribeNFT;
    }

    /**
     * @notice Subscribe to an address(es) with a signature.
     *
     * @param sender The sender address.
     * @param profileIds The profile ids to subscribed to.
     * @param preDatas The subscription data for preprocess.
     * @param postDatas The subscription data for postprocess.
     * @param sig The EIP712 signature.
     * @dev the function requires the stated to be not paused.
     * @return uint256[] The subscription nft ids.
     */
    function subscribeWithSig(
        uint256[] calldata profileIds,
        bytes[] calldata preDatas,
        bytes[] calldata postDatas,
        address sender,
        DataTypes.EIP712Signature calldata sig
    ) external returns (uint256[] memory) {
        // let _subscribe handle length check
        uint256 preLength = preDatas.length;
        bytes32[] memory preHashes = new bytes32[](preLength);
        for (uint256 i = 0; i < preLength; ) {
            preHashes[i] = keccak256(preDatas[i]);
            unchecked {
                ++i;
            }
        }
        uint256 postLength = postDatas.length;
        bytes32[] memory postHashes = new bytes32[](postLength);
        for (uint256 i = 0; i < postLength; ) {
            postHashes[i] = keccak256(postDatas[i]);
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
                        keccak256(abi.encodePacked(preHashes)),
                        keccak256(abi.encodePacked(postHashes)),
                        nonces[sender]++,
                        sig.deadline
                    )
                )
            ),
            sender,
            sig
        );
        return _subscribe(sender, profileIds, preDatas, postDatas);
    }

    /**
     * @notice The subscription functionality.
     *
     * @param profileIds The profile ids to subscribed to.
     * @param preDatas The subscription data for preprocess.
     * @param postDatas The subscription data for postprocess.
     * @return uint256[] The subscription nft ids.
     * @dev the function requires the stated to be not paused.
     */
    function subscribe(
        uint256[] calldata profileIds,
        bytes[] calldata preDatas,
        bytes[] calldata postDatas
    ) external returns (uint256[] memory) {
        return _subscribe(msg.sender, profileIds, preDatas, postDatas);
    }

    function _collect(
        address collector,
        uint256 profileId,
        uint256 essenceId,
        bytes calldata preData,
        bytes calldata postData
    ) internal returns (uint256) {
        _requireMinted(profileId);
        require(
            bytes(_essenceByIdByProfileId[profileId][essenceId].tokenURI)
                .length != 0,
            "ESSENCE_NOT_REGISTERED"
        );
        address essenceNFT = _essenceByIdByProfileId[profileId][essenceId]
            .essenceNFT;
        address essenceMw = _essenceByIdByProfileId[profileId][essenceId]
            .essenceMw;

        // lazy deploy essence NFT
        if (essenceNFT == address(0)) {
            bytes memory initData = abi.encodeWithSelector(
                IEssenceNFT.initialize.selector,
                profileId,
                essenceId,
                _essenceByIdByProfileId[profileId][essenceId].name,
                _essenceByIdByProfileId[profileId][essenceId].symbol
            );
            essenceNFT = address(new BeaconProxy(ESSENCE_BEACON, initData));
            _essenceByIdByProfileId[profileId][essenceId]
                .essenceNFT = essenceNFT;
            emit DeployEssenceNFT(profileId, essenceId, essenceNFT);
        }
        // run middleware before collectign essence
        if (essenceMw != address(0)) {
            IEssenceMiddleware(essenceMw).preProcess(
                profileId,
                essenceId,
                collector,
                essenceNFT,
                preData
            );
        }
        uint256 tokenId = IEssenceNFT(essenceNFT).mint(collector);
        if (essenceMw != address(0)) {
            IEssenceMiddleware(essenceMw).postProcess(
                profileId,
                essenceId,
                collector,
                essenceNFT,
                postData
            );
        }

        emit CollectEssence(collector, profileId, preData, postData);
        return tokenId;
    }

    function collect(
        uint256 profileId,
        uint256 essenceId,
        bytes calldata preData,
        bytes calldata postData
    ) external returns (uint256 tokenId) {
        return _collect(msg.sender, profileId, essenceId, preData, postData);
    }

    function collectWithSig(
        uint256 profileId,
        uint256 essenceId,
        bytes calldata preData,
        bytes calldata postData,
        address sender,
        DataTypes.EIP712Signature calldata sig
    ) external returns (uint256 tokenId) {
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._COLLECT_TYPEHASH,
                        profileId,
                        essenceId,
                        keccak256(preData),
                        keccak256(postData),
                        nonces[sender]++,
                        sig.deadline
                    )
                )
            ),
            sender,
            sig
        );
        return _collect(sender, profileId, essenceId, preData, postData);
    }

    // TODO: test
    function registerEssence(
        uint256 profileId,
        string calldata name,
        string calldata symbol,
        string calldata essenceTokenURI,
        address essenceMw,
        bytes calldata initData
    ) external onlyProfileOwnerOrOperator(profileId) returns (uint256) {
        return
            _registerEssence(
                profileId,
                name,
                symbol,
                essenceTokenURI,
                essenceMw,
                initData
            );
    }

    function _registerEssence(
        uint256 profileId,
        string calldata name,
        string calldata symbol,
        string calldata essenceTokenURI,
        address essenceMw,
        bytes calldata prepareData
    ) internal returns (uint256) {
        require(
            essenceMw == address(0) || _essenceMwAllowlist[essenceMw],
            "ESSENCE_MW_NOT_ALLOWED"
        );
        uint256 id = ++_profileById[profileId].essenceCount;
        _essenceByIdByProfileId[profileId][id].name = name;
        _essenceByIdByProfileId[profileId][id].symbol = symbol;
        _essenceByIdByProfileId[profileId][id].tokenURI = essenceTokenURI;
        bytes memory returnData;
        if (essenceMw != address(0)) {
            _essenceByIdByProfileId[profileId][id].essenceMw = essenceMw;
            returnData = IEssenceMiddleware(essenceMw).prepare(
                profileId,
                id,
                prepareData
            );
        }
        emit RegisterEssence(
            profileId,
            id,
            name,
            symbol,
            essenceTokenURI,
            essenceMw,
            returnData
        );
        return id;
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
    function setSubscribeMw(
        uint256 profileId,
        address mw,
        bytes calldata prepareData
    ) external onlyProfileOwner(profileId) {
        require(
            mw == address(0) || _subscribeMwAllowlist[mw],
            "SUB_MW_NOT_ALLOWED"
        );
        _subscribeByProfileId[profileId].subscribeMw = mw;
        bytes memory returnData;
        if (mw != address(0)) {
            returnData = ISubscribeMiddleware(mw).prepare(
                profileId,
                prepareData
            );
        }
        emit SetSubscribeMw(profileId, mw, returnData);
    }

    // TODO: withSig
    // TODO: integration test
    function setSubscribeTokenURI(
        uint256 profileId,
        string calldata subscribeTokenURI
    ) external onlyProfileOwnerOrOperator(profileId) {
        _subscribeByProfileId[profileId].tokenURI = subscribeTokenURI;
        emit SetSubscribeTokenURI(profileId, subscribeTokenURI);
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
     * @notice Allows the essence middleware.
     *
     * @param mw The middleware address.
     * @param allowed The allowance state.
     */
    function allowEssenceMw(address mw, bool allowed) external requiresAuth {
        bool preAllowed = _essenceMwAllowlist[mw];
        _essenceMwAllowlist[mw] = allowed;
        emit AllowEssenceMw(mw, preAllowed, allowed);
    }

    /**
     * @notice Checks if the essence middleware is allowed.
     *
     * @param mw The middleware address.
     * @return bool The allowance state.
     */
    function isEssenceMwAllowed(address mw) external view returns (bool) {
        return _essenceMwAllowlist[mw];
    }
}
