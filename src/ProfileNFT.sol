// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { IProfileNFT } from "./interfaces/IProfileNFT.sol";
import { CyberNFTBase } from "./base/CyberNFTBase.sol";
import { Constants } from "./libraries/Constants.sol";
import { DataTypes } from "./libraries/DataTypes.sol";
import { LibString } from "./libraries/LibString.sol";
import { Base64 } from "./dependencies/openzeppelin/Base64.sol";
import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";

// TODO: Owner cannot be set with conflicting role for capacity
contract ProfileNFT is CyberNFTBase, IProfileNFT, UUPSUpgradeable {
    address public immutable ENGINE;
    mapping(uint256 => DataTypes.ProfileStruct) internal _profileById;
    mapping(bytes32 => uint256) internal _profileIdByHandleHash;
    mapping(uint256 => string) internal _metadataById;
    mapping(uint256 => mapping(address => bool)) internal _operatorApproval; // TODO: reconsider if useful
    uint256 private constant VERSION = 1;

    modifier onlyEngine() {
        require(msg.sender == address(ENGINE), "Only Engine");
        _;
    }

    // ENGINE for createProfile, setSubscribeNFT
    constructor(address _engine) {
        require(_engine != address(0), "Engine address cannot be 0");
        ENGINE = _engine;
    }

    // TODO: enable this, currently disabled for better testability
    // constructor() {
    //     _disableInitializers();
    // }

    function initialize(string calldata _name, string calldata _symbol)
        external
        initializer
    {
        CyberNFTBase._initialize(_name, _symbol);
    }

    function checkHandleAvailability(string calldata handle)
        external
        view
        returns (bool, string memory)
    {
        if (_validateHandleLength(handle) == false)
            return (false, "Handle has invalid length");

        if (_validateHandleCharacters(handle) == false)
            return (false, "Handle contains invalid character");

        bytes32 handleHash = keccak256(bytes(handle));
        if (!_exists(_profileIdByHandleHash[handleHash]))
            return (true, "Handle available");
        return (false, "Handle is not available");
    }

    function createProfile(
        address to,
        DataTypes.CreateProfileParams calldata vars
    ) external override onlyEngine returns (uint256) {
        require(
            msg.sender == address(ENGINE),
            "Only Engine could create profile"
        );
        //_validateHandle(vars.handle);
        require(
            (_validateHandleLength(vars.handle) == true),
            "Handle has invalid length"
        );

        require(
            (_validateHandleCharacters(vars.handle) == true),
            "Handle contains invalid character"
        );

        bytes32 handleHash = keccak256(bytes(vars.handle));
        require(!_exists(_profileIdByHandleHash[handleHash]), "Handle taken");

        // TODO: unchecked
        _mint(to);
        _profileById[_totalCount] = DataTypes.ProfileStruct({
            handle: vars.handle,
            imageURI: vars.imageURI
        });

        _profileIdByHandleHash[handleHash] = _totalCount;
        return _totalCount;
    }

    function getHandleByProfileId(uint256 profileId)
        external
        view
        returns (string memory)
    {
        // TODO: maybe remove this check
        require(_exists(profileId), "ERC721: invalid token ID");
        return _profileById[profileId].handle;
    }

    function getProfileIdByHandle(string calldata handle)
        external
        view
        returns (uint256)
    {
        bytes32 handleHash = keccak256(bytes(handle));
        return _profileIdByHandleHash[handleHash];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        string memory formattedName = string(
            abi.encodePacked("@", _profileById[tokenId].handle)
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"',
                            formattedName,
                            '","description":"',
                            formattedName,
                            ' - CyberConnect profile","attributes":[{"trait_type":"id","value":"#',
                            LibString.toString(tokenId),
                            '"},{"trait_type":"owner","value":"',
                            // TODO: use uint160 will somehow remove the zero padding for 0x address
                            LibString.toHexString(ownerOf(tokenId)),
                            '"},{"trait_type":"handle","value":"',
                            formattedName,
                            '"}]}'
                        )
                    )
                )
            );
    }

    function _validateHandleLength(string calldata handle)
        internal
        pure
        returns (bool)
    {
        bytes memory byteHandle = bytes(handle);
        return (byteHandle.length <= Constants._MAX_HANDLE_LENGTH &&
            byteHandle.length > 0);
    }

    function _validateHandleCharacters(string calldata handle)
        internal
        pure
        returns (bool)
    {
        bytes memory byteHandle = bytes(handle);
        uint256 byteHandleLength = byteHandle.length;
        for (uint256 i = 0; i < byteHandleLength; ) {
            bytes1 b = byteHandle[i];
            if ((b < "0" || b > "9") && (b < "a" || b > "z") && b != "_")
                return false;

            unchecked {
                ++i;
            }
        }
        return true;
    }

    function getOperatorApproval(uint256 profileId, address operator)
        external
        view
        returns (bool)
    {
        _requireMinted(profileId);
        return _operatorApproval[profileId][operator];
    }

    function setOperatorApproval(
        uint256 profileId,
        address operator,
        bool approved
    ) external onlyEngine {
        require(operator != address(0), "Operator address cannot be 0");
        _operatorApproval[profileId][operator] = approved;
    }

    function setMetadata(uint256 profileId, string calldata metadata)
        external
        onlyEngine
    {
        _metadataById[profileId] = metadata;
    }

    function getMetadata(uint256 profileId)
        external
        view
        returns (string memory)
    {
        _requireMinted(profileId);
        return _metadataById[profileId];
    }

    // TODO: write a test for upgrade profile nft
    // UUPS upgradeability
    function version() external pure virtual returns (uint256) {
        return VERSION;
    }

    // UUPS upgradeability
    function _authorizeUpgrade(address) internal override onlyEngine {}
}
