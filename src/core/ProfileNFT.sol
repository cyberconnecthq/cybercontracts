// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { ReentrancyGuard } from "../dependencies/openzeppelin/ReentrancyGuard.sol";
import { Pausable } from "../dependencies/openzeppelin/Pausable.sol";

import { IProfileNFT } from "../interfaces/IProfileNFT.sol";
import { IUpgradeable } from "../interfaces/IUpgradeable.sol";
import { ICyberEngine } from "../interfaces/ICyberEngine.sol";
import { IProfileNFTDescriptor } from "../interfaces/IProfileNFTDescriptor.sol";
import { ISubscribeNFT } from "../interfaces/ISubscribeNFT.sol";
import { IEssenceNFT } from "../interfaces/IEssenceNFT.sol";
import { ISubscribeMiddleware } from "../interfaces/ISubscribeMiddleware.sol";
import { IProfileMiddleware } from "../interfaces/IProfileMiddleware.sol";
import { IEssenceMiddleware } from "../interfaces/IEssenceMiddleware.sol";
import { IProfileDeployer } from "../interfaces/IProfileDeployer.sol";

import { Constants } from "../libraries/Constants.sol";
import { DataTypes } from "../libraries/DataTypes.sol";
import { LibString } from "../libraries/LibString.sol";
import { Actions } from "../libraries/Actions.sol";

import { CyberNFTBase } from "../base/CyberNFTBase.sol";
import { ProfileNFTStorage } from "../storages/ProfileNFTStorage.sol";

/**
 * @title Profile NFT
 * @author CyberConnect
 * @notice This contract is used to create a profile NFT.
 */
contract ProfileNFT is
    Pausable,
    ReentrancyGuard,
    CyberNFTBase,
    UUPSUpgradeable,
    ProfileNFTStorage,
    IUpgradeable,
    IProfileNFT
{
    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/

    /* solhint-disable var-name-mixedcase */

    address public immutable SUBSCRIBE_BEACON;
    address public immutable ESSENCE_BEACON;
    address public immutable ENGINE;

    /* solhint-enable var-name-mixedcase */

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

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

    /**
     * @notice Checks that the namespace owner is the sender address.
     */
    modifier onlyNamespaceOwner() {
        require(_namespaceOwner == msg.sender, "ONLY_NAMESPACE_OWNER");
        _;
    }

    /**
     * @notice Checks that the CyberEngine is the sender address.
     */
    modifier onlyEngine() {
        require(ENGINE == msg.sender, "ONLY_ENGINE");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        (
            address engine,
            address subBeacon,
            address essenceBeacon
        ) = IProfileDeployer(msg.sender).profileParams();
        ENGINE = engine;
        SUBSCRIBE_BEACON = subBeacon;
        ESSENCE_BEACON = essenceBeacon;
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the Profile NFT.
     *
     * @param _owner Owner of the Profile NFT.
     * @param name Name to set for the Profile NFT.
     * @param symbol Symbol to set for the Profile NFT.
     */
    function initialize(
        address _owner,
        string calldata name,
        string calldata symbol
    ) external initializer {
        CyberNFTBase._initialize(name, symbol);
        ReentrancyGuard.__ReentrancyGuard_init();

        _namespaceOwner = _owner;
        emit Initialize(_owner);
        // start with paused
        _pause();
    }

    /// @inheritdoc IProfileNFT
    function createProfile(
        DataTypes.CreateProfileParams calldata params,
        bytes calldata preData,
        bytes calldata postData
    ) external payable override nonReentrant returns (uint256 tokenID) {
        address profileMw = ICyberEngine(ENGINE).getProfileMwByNamespace(
            address(this)
        );

        if (profileMw != address(0)) {
            IProfileMiddleware(profileMw).preProcess{ value: msg.value }(
                params,
                preData
            );
        }

        tokenID = _createProfile(params);
        if (profileMw != address(0)) {
            IProfileMiddleware(profileMw).postProcess(params, postData);
        }

        emit CreateProfile(
            params.to,
            tokenID,
            params.handle,
            params.avatar,
            params.metadata
        );
    }

    /**
     * @notice Subscribe to an address(es) with a signature.
     *
     * @param sender The sender address.
     * @param params The params for subscription.
     * @param preDatas The subscription data for preprocess.
     * @param postDatas The subscription data for postprocess.
     * @param sig The EIP712 signature.
     * @dev the function requires the stated to be not paused.
     * @return uint256[] The subscription nft ids.
     */
    function subscribeWithSig(
        DataTypes.SubscribeParams calldata params,
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
                        keccak256(abi.encodePacked(params.profileIds)),
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
        return _subscribe(sender, params, preDatas, postDatas);
    }

    /**
     * @notice The subscription functionality.
     *
     * @param params The params for subscription.
     * @param preDatas The subscription data for preprocess.
     * @param postDatas The subscription data for postprocess.
     * @return uint256[] The subscription nft ids.
     * @dev the function requires the stated to be not paused.
     */
    function subscribe(
        DataTypes.SubscribeParams calldata params,
        bytes[] calldata preDatas,
        bytes[] calldata postDatas
    ) external returns (uint256[] memory) {
        return _subscribe(msg.sender, params, preDatas, postDatas);
    }

    function collect(
        DataTypes.CollectParams calldata params,
        bytes calldata preData,
        bytes calldata postData
    ) external returns (uint256 tokenId) {
        return _collect(msg.sender, params, preData, postData);
    }

    function collectWithSig(
        DataTypes.CollectParams calldata params,
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
                        params.profileId,
                        params.essenceId,
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
        return _collect(sender, params, preData, postData);
    }

    // TODO: test
    function registerEssence(
        DataTypes.RegisterEssenceParams calldata params,
        bytes calldata initData
    ) external onlyProfileOwnerOrOperator(params.profileId) returns (uint256) {
        require(
            params.essenceMw == address(0) ||
                ICyberEngine(ENGINE).isEssenceMwAllowed(params.essenceMw),
            "ESSENCE_MW_NOT_ALLOWED"
        );

        (uint256 tokenID, bytes memory returnData) = Actions.registerEssence(
            DataTypes.RegisterEssenceData(
                params.profileId,
                params.name,
                params.symbol,
                params.essenceTokenURI,
                params.essenceMw,
                initData
            ),
            _profileById,
            _essenceByIdByProfileId
        );

        emit RegisterEssence(
            params.profileId,
            tokenID,
            params.name,
            params.symbol,
            params.essenceTokenURI,
            params.essenceMw,
            returnData
        );
        return tokenID;
    }

    /**
     * @notice Changes the pause state of the profile nft.
     *
     * @param toPause The pause state.
     */
    function pause(bool toPause) external onlyNamespaceOwner {
        if (toPause) {
            super._pause();
        } else {
            super._unpause();
        }
    }

    /// @inheritdoc IProfileNFT
    function setAnimationTemplate(string calldata template)
        external
        onlyNamespaceOwner
    {
        IProfileNFTDescriptor(_nftDescriptor).setAnimationTemplate(template);

        emit SetAnimationTemplate(template);
    }

    function setNamespaceOwner(address owner) external onlyNamespaceOwner {
        address preOwner = _namespaceOwner;
        _namespaceOwner = owner;

        emit SetNamespaceOwner(preOwner, owner);
    }

    /// @inheritdoc IProfileNFT
    function setNFTDescriptor(address descriptor)
        external
        override
        onlyNamespaceOwner
    {
        _nftDescriptor = descriptor;
        emit SetNFTDescriptor(descriptor);
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

    // TODO: withSig
    function setSubscribeMw(
        uint256 profileId,
        address mw,
        bytes calldata prepareData
    ) external onlyProfileOwner(profileId) {
        require(
            mw == address(0) || ICyberEngine(ENGINE).isSubscribeMwAllowed(mw),
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

    // TODO: withSig
    // TODO: integration test
    function setSubscribeTokenURI(
        uint256 profileId,
        string calldata subscribeTokenURI
    ) external onlyProfileOwnerOrOperator(profileId) {
        _subscribeByProfileId[profileId].tokenURI = subscribeTokenURI;
        emit SetSubscribeTokenURI(profileId, subscribeTokenURI);
    }

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    // TODO: UUPS base contracts for functions
    // TODO: write a test for upgrade profile nft
    function version() external pure virtual override returns (uint256) {
        return _VERSION;
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

    /// @inheritdoc IProfileNFT
    function getPrimaryProfile(address user)
        external
        view
        override
        returns (uint256)
    {
        return _addressToPrimaryProfile[user];
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

    /// @inheritdoc IProfileNFT
    function getNFTDescriptor() external view override returns (address) {
        return _nftDescriptor;
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

    /// @inheritdoc IProfileNFT
    function getNamespaceOwner() external view override returns (address) {
        return _namespaceOwner;
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override whenNotPaused {
        super.transferFrom(from, to, id);
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC VIEW
    //////////////////////////////////////////////////////////////*/

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
    function getOperatorApproval(uint256 profileId, address operator)
        public
        view
        returns (bool)
    {
        _requireMinted(profileId);
        return _operatorApproval[profileId][operator];
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    // UUPS upgradeability
    function _authorizeUpgrade(address) internal override onlyEngine {}

    /**
     * @notice The subscription functionality.
     *
     * @param sender The sender address.
     * @param params The params for subscription.
     * @param preDatas The subscription data used in pre process.
     * @param postDatas The subscription data used in post process.
     * @return result The subscription nft ids.
     */
    function _subscribe(
        address sender,
        DataTypes.SubscribeParams calldata params,
        bytes[] calldata preDatas,
        bytes[] calldata postDatas
    ) internal returns (uint256[] memory) {
        for (uint256 i = 0; i < params.profileIds.length; i++) {
            _requireMinted(params.profileIds[i]);
        }

        uint256[] memory result = Actions.subscribe(
            DataTypes.SubscribeData(
                sender,
                params.profileIds,
                preDatas,
                postDatas,
                SUBSCRIBE_BEACON
            ),
            _subscribeByProfileId,
            _profileById
        );

        emit Subscribe(sender, params.profileIds, preDatas, postDatas);
        // if (deployedSubscribeNFT != address(0)) {
        //     emit DeploySubscribeNFT(profileId, deployedSubscribeNFT);
        // }
        return result;
    }

    function _collect(
        address collector,
        DataTypes.CollectParams calldata params,
        bytes calldata preData,
        bytes calldata postData
    ) internal returns (uint256) {
        _requireMinted(params.profileId);

        (uint256 tokenID, address deployedEssenceNFT) = Actions.collect(
            DataTypes.CollectData(
                collector,
                params.profileId,
                params.essenceId,
                preData,
                postData,
                ESSENCE_BEACON
            ),
            _essenceByIdByProfileId
        );

        emit CollectEssence(collector, params.profileId, preData, postData);

        if (deployedEssenceNFT != address(0)) {
            emit DeployEssenceNFT(
                params.profileId,
                params.essenceId,
                deployedEssenceNFT
            );
        }
    }

    function _createProfile(DataTypes.CreateProfileParams calldata params)
        internal
        returns (uint256 tokenID)
    {
        bytes32 handleHash = keccak256(bytes(params.handle));
        require(!_exists(_profileIdByHandleHash[handleHash]), "HANDLE_TAKEN");

        tokenID = _mint(params.to);

        _profileById[_totalCount].handle = params.handle;
        _profileById[_totalCount].avatar = params.avatar;
        _metadataById[_totalCount] = params.metadata;
        _profileIdByHandleHash[handleHash] = _totalCount;

        if (_addressToPrimaryProfile[params.to] == 0) {
            _addressToPrimaryProfile[params.to] = tokenID;
            emit SetPrimaryProfile(params.to, tokenID);
        }
    }

    function _setPrimaryProfile(address user, uint256 profileId) internal {
        _addressToPrimaryProfile[user] = profileId;
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
}
