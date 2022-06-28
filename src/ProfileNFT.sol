// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { IProfileNFT } from "./interfaces/IProfileNFT.sol";
import { IUpgradeable } from "./interfaces/IUpgradeable.sol";
import { CyberNFTBase } from "./base/CyberNFTBase.sol";
import { Constants } from "./libraries/Constants.sol";
import { DataTypes } from "./libraries/DataTypes.sol";
import { LibString } from "./libraries/LibString.sol";
import { Base64 } from "./dependencies/openzeppelin/Base64.sol";
import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { ProfileNFTStorage } from "./storages/ProfileNFTStorage.sol";

/**
 * @title Profile NFT
 * @author CyberConnect
 * @notice This contract is used to create a profile NFT.
 */

// TODO: Owner cannot be set with conflicting role for capacity
contract ProfileNFT is
    CyberNFTBase,
    UUPSUpgradeable,
    ProfileNFTStorage,
    IUpgradeable,
    IProfileNFT
{
    // Immutable
    address public immutable ENGINE;

    modifier onlyEngine() {
        require(msg.sender == address(ENGINE), "Only Engine");
        _;
    }

    constructor(address _engine) {
        require(_engine != address(0), "Engine address cannot be 0");
        ENGINE = _engine;
        _disableInitializers();
    }

    function initialize(
        string calldata _name,
        string calldata _symbol,
        string calldata animationTemplate_,
        string memory imageTemplate_
    ) external initializer {
        CyberNFTBase._initialize(_name, _symbol);
        _animationTemplate = animationTemplate_;
        _imageTemplate = imageTemplate_;
    }

    /// @inheritdoc IProfileNFT
    function createProfile(DataTypes.CreateProfileParams calldata params)
        external
        override
        onlyEngine
        returns (uint256)
    {
        _requiresValidHandle(params.handle);

        bytes32 handleHash = keccak256(bytes(params.handle));
        require(!_exists(_profileIdByHandleHash[handleHash]), "Handle taken");

        // TODO: unchecked
        _mint(params.to);
        _profileById[_totalCount] = DataTypes.ProfileStruct({
            handle: params.handle,
            avatar: params.avatar
        });

        _profileIdByHandleHash[handleHash] = _totalCount;
        _metadataById[_totalCount] = params.metadata;
        return _totalCount;
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
     * @notice generates the metadata json object.
     *
     * @param tokenId The profile NFT token ID.
     * @return memory the metadata json object.
     * @dev it requires the tokenId to be already minted.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        string memory handle = _profileById[tokenId].handle;
        string memory formattedName = string(abi.encodePacked("@", handle));
        string memory animationURL = string(
            abi.encodePacked(animationTemplate, "?handle=", handle)
        );
        string memory imageURL = string(
            abi.encodePacked(imageTemplate, "?handle=", handle)
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"',
                            formattedName,
                            '","description":"CyberConnect profile for ',
                            formattedName,
                            '","image":"',
                            imageURL,
                            '","animation_url":"',
                            animationURL,
                            '","attributes":[{"trait_type":"id","value":"',
                            LibString.toString(tokenId),
                            '"},{"trait_type":"length","value":"',
                            LibString.toString(bytes(handle).length),
                            '"},{"trait_type":"handle","value":"',
                            formattedName,
                            '"}]}'
                        )
                    )
                )
            );
    }

    /**
     * @notice verifies a handle for length and invalid characters.
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
                "Handle contains invalid character"
            );
            // optimation
            unchecked {
                ++i;
            }
        }
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
    function setAnimationTemplate(string calldata template)
        external
        override
        onlyEngine
    {
        animationTemplate = template;
    }

    /// @inheritdoc IProfileNFT
    function setImageTemplate(string calldata template)
        external
        override
        onlyEngine
    {
        imageTemplate = template;
    }

    /// @inheritdoc IProfileNFT
    function setAvatar(uint256 profileId, string calldata avatar)
        external
        override
        onlyEngine
    {
        _profileById[profileId].avatar = avatar;
    }

    // TODO: write a test for upgrade profile nft
    // UUPS upgradeability
    function version() external pure virtual returns (uint256) {
        return VERSION;
    }

    // UUPS upgradeability
    function _authorizeUpgrade(address) internal override onlyEngine {}
}
