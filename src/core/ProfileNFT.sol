// SPDX-License-Identifier: MIT

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

    /**
     * @notice Initializes the Profile NFT.
     *
     * @param name Name to set for the Profile NFT.
     * @param symbol Symbol to set for the Profile NFT.
     * @param animationTemplate Template animation url to set for the Profile NFT.
     * @param imageTemplate symbol to set for the Profile NFT.
     */
    function initialize(
        string calldata name,
        string calldata symbol,
        string calldata animationTemplate,
        string memory imageTemplate
    ) external initializer {
        CyberNFTBase._initialize(name, symbol);
        _animationTemplate = animationTemplate;
        _imageTemplate = imageTemplate;
        // start with paused
        _pause();
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

        uint256 id = _mint(params.to);
        
        _profileById[_totalCount] = DataTypes.ProfileStruct({
            handle: params.handle,
            avatar: params.avatar
        });

        _profileIdByHandleHash[handleHash] = _totalCount;
        _metadataById[_totalCount] = params.metadata;
        return id;
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
        string memory formattedName = string(abi.encodePacked("@", handle));
        string memory animationURL = string(
            abi.encodePacked(_animationTemplate, "?handle=", handle)
        );
        string memory imageURL = string(
            abi.encodePacked(_imageTemplate, "?handle=", handle)
        );
        address subscribeNFT = CyberEngine(ENGINE).getSubscribeNFT(tokenId);
        uint256 subscribers;
        if (subscribeNFT == address(0)) {
            subscribers = 0;
        } else {
            subscribers = CyberNFTBase(subscribeNFT).totalSupply();
        }
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
                            '","attributes":',
                            _genAttributes(
                                LibString.toString(tokenId),
                                LibString.toString(bytes(handle).length),
                                LibString.toString(subscribers),
                                formattedName
                            ),
                            "}"
                        )
                    )
                )
            );
    }

    function _genAttributes(
        string memory tokenId,
        string memory length,
        string memory subscribers,
        string memory name
    ) private pure returns (bytes memory) {
        return
            abi.encodePacked(
                '[{"trait_type":"id","value":"',
                tokenId,
                '"},{"trait_type":"length","value":"',
                length,
                '"},{"trait_type":"subscribers","value":"',
                subscribers,
                '"},{"trait_type":"handle","value":"',
                name,
                '"}]'
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
    function setAnimationTemplate(string calldata template)
        external
        override
        onlyEngine
    {
        _animationTemplate = template;
    }

    /// @inheritdoc IProfileNFT
    function setImageTemplate(string calldata template)
        external
        override
        onlyEngine
    {
        _imageTemplate = template;
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

    /// @inheritdoc IProfileNFT
    function getAnimationTemplate()
        external
        view
        override
        returns (string memory)
    {
        return _animationTemplate;
    }

    /// @inheritdoc IProfileNFT
    function getImageTemplate() external view override returns (string memory) {
        return _imageTemplate;
    }

    // TODO: write a test for upgrade profile nft
    // UUPS upgradeability
    function version() external pure virtual override returns (uint256) {
        return _VERSION;
    }

    // UUPS upgradeability
    function _authorizeUpgrade(address) internal override onlyEngine {}

    // pausable
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
}
