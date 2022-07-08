// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IProfileNFT } from "../interfaces/IProfileNFT.sol";
import { IUpgradeable } from "../interfaces/IUpgradeable.sol";
import { CyberNFTBase } from "../base/CyberNFTBase.sol";
import { Constants } from "../libraries/Constants.sol";
import { DataTypes } from "../libraries/DataTypes.sol";
import { LibString } from "../libraries/LibString.sol";
import { Base64 } from "../dependencies/openzeppelin/Base64.sol";
import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { ProfileNFTStorage } from "../storages/ProfileNFTStorage.sol";
import { Pausable } from "../dependencies/openzeppelin/Pausable.sol";
import { CyberEngine } from "./CyberEngine.sol";
import { IProfileNFTDescriptor } from "../interfaces/IProfileNFTDescriptor.sol";

/**
 * @title Profile NFT
 * @author CyberConnect
 * @notice This contract is used to create a profile NFT.
 */

contract ProfileNFT is
    Pausable,
    CyberNFTBase,
    UUPSUpgradeable,
    ProfileNFTStorage,
    IUpgradeable,
    IProfileNFT
{
    // Immutable
    address public immutable ENGINE; // solhint-disable-line

    /**
     * @notice Checks that sender is engine address.
     */
    modifier onlyEngine() {
        require(msg.sender == address(ENGINE), "Only Engine");
        _;
    }

    constructor(address _engine) {
        require(_engine != address(0), "Engine address cannot be 0");
        ENGINE = _engine;
        _disableInitializers();
    }

    /**
     * @notice Initializes the Profile NFT.
     *
     * @param name Name to set for the Profile NFT.
     * @param symbol Symbol to set for the Profile NFT.
     * @param profileNFTDescriptor The profile NFT descriptor address to set for the Profile NFT.
     */
    function initialize(
        string calldata name,
        string calldata symbol,
        address profileNFTDescriptor
    ) external initializer {
        require(
            profileNFTDescriptor != address(0),
            "Descriptor address cannot be 0"
        );
        CyberNFTBase._initialize(name, symbol, _VERSION_STR);
        _profileNFTDescriptor = profileNFTDescriptor;
        // start with paused
        _pause();
    }

    /// @inheritdoc IProfileNFT
    function createProfile(DataTypes.CreateProfileParams calldata params)
        external
        override
        onlyEngine
        returns (uint256 id, bool primaryProfileSet)
    {
        _requiresValidHandle(params.handle);

        bytes32 handleHash = keccak256(bytes(params.handle));
        require(!_exists(_profileIdByHandleHash[handleHash]), "Handle taken");

        id = _mint(params.to);

        _profileById[_totalCount] = DataTypes.ProfileStruct({
            handle: params.handle,
            avatar: params.avatar
        });

        _profileIdByHandleHash[handleHash] = _totalCount;
        _metadataById[_totalCount] = params.metadata;

        if (_addressToPrimaryProfile[params.to] == 0) {
            _setPrimaryProfile(params.to, id);
            primaryProfileSet = true;
        }
    }

    /// @inheritdoc IProfileNFT
    function getHandleByProfileId(uint256 profileId)
        external
        view
        override
        returns (string memory)
    {
        require(_exists(profileId), "ERC721: invalid token ID");
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
     * @return memory The metadata json object.
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
        address subscribeNFT = CyberEngine(ENGINE).getSubscribeNFT(tokenId);
        uint256 subscribers;
        if (subscribeNFT == address(0)) {
            subscribers = 0;
        } else {
            subscribers = CyberNFTBase(subscribeNFT).totalSupply();
        }

        return
            IProfileNFTDescriptor(_profileNFTDescriptor).tokenURI(
                IProfileNFTDescriptor.ConstructTokenURIParams({
                    tokenId: tokenId,
                    handle: handle,
                    subscribers: subscribers
                })
            );
    }

    /**
     * @notice Verifies a handle for length and invalid characters.
     *
     * @param handle The handle to verify.
     * @dev Throws if:
     * - handle is empty
     * - handle is too long
     * - handle contains invalid characters
     */
    function _requiresValidHandle(string calldata handle) internal pure {
        bytes memory byteHandle = bytes(handle);
        require(
            byteHandle.length <= Constants._MAX_HANDLE_LENGTH &&
                byteHandle.length > 0,
            "Handle has invalid length"
        );

        uint256 byteHandleLength = byteHandle.length;
        for (uint256 i = 0; i < byteHandleLength; ) {
            bytes1 b = byteHandle[i];
            require(
                (b >= "0" && b <= "9") || (b >= "a" && b <= "z") || b == "_",
                "Handle has invalid character"
            );
            // optimation
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IProfileNFT
    function getProfileNFTDescriptor()
        external
        view
        override
        returns (address)
    {
        return _profileNFTDescriptor;
    }

    /// @inheritdoc IProfileNFT
    function getOperatorApproval(uint256 profileId, address operator)
        external
        view
        override
        returns (bool)
    {
        _requireMinted(profileId);
        return _operatorApproval[profileId][operator];
    }

    /// @inheritdoc IProfileNFT
    function setOperatorApproval(
        uint256 profileId,
        address operator,
        bool approved
    ) external override onlyEngine {
        require(operator != address(0), "Operator address cannot be 0");
        _operatorApproval[profileId][operator] = approved;
    }

    /// @inheritdoc IProfileNFT
    function setMetadata(uint256 profileId, string calldata metadata)
        external
        override
        onlyEngine
    {
        require(
            bytes(metadata).length <= Constants._MAX_URI_LENGTH,
            "Metadata has invalid length"
        );
        _metadataById[profileId] = metadata;
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
    function setProfileNFTDescriptor(address descriptor)
        external
        override
        onlyEngine
    {
        _profileNFTDescriptor = descriptor;
    }

    /// @inheritdoc IProfileNFT
    function setAvatar(uint256 profileId, string calldata avatar)
        external
        override
        onlyEngine
    {
        require(
            bytes(avatar).length <= Constants._MAX_URI_LENGTH,
            "Avatar has invalid length"
        );
        _profileById[profileId].avatar = avatar;
    }

    // TODO: write a test for upgrade profile nft
    function version() external pure virtual override returns (uint256) {
        return _VERSION;
    }

    // UUPS upgradeability
    function _authorizeUpgrade(address) internal override onlyEngine {}

    /**
     * @notice Changes the pause state of the profile nft.
     *
     * @param toPause The pause state.
     */
    function pause(bool toPause) external onlyEngine {
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
    function setPrimaryProfile(address user, uint256 profileId)
        public
        override
        onlyEngine
    {
        _requireMinted(profileId);
        _setPrimaryProfile(user, profileId);
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
}
