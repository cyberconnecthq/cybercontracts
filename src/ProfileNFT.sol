pragma solidity 0.8.14;

import "./CyberNFTBase.sol";
import "solmate/auth/authorities/RolesAuthority.sol";
import { Authority } from "solmate/auth/Auth.sol";
import { Constants } from "./libraries/Constants.sol";
import { DataTypes } from "./libraries/DataTypes.sol";
import { LibString } from "./libraries/LibString.sol";
import { Base64 } from "./libraries/oz/Base64.sol";

// TODO: Owner cannot be set with conflicting role for capacity
contract ProfileNFT is CyberNFTBase, Auth {
    mapping(uint256 => DataTypes.ProfileStruct) internal _profileById;
    mapping(bytes32 => uint256) internal _profileIdByHandleHash;

    constructor(
        string memory _name,
        string memory _symbol,
        address _owner,
        RolesAuthority _rolesAuthority
    ) CyberNFTBase(_name, _symbol) Auth(_owner, _rolesAuthority) {}

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf[tokenId] != address(0);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        // TODO: maybe remove this check
        require(_exists(tokenId), "ERC721: invalid token ID");
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
                            LibString.toHexString(uint160(owner)),
                            '"},{"trait_type":"handle","value":"',
                            formattedName,
                            '"}]}'
                        )
                    )
                )
            );
    }

    function createProfile(address to, DataTypes.ProfileStruct calldata vars)
        external
        requiresAuth
        returns (uint256)
    {
        _validateHandle(vars.handle);

        bytes32 handleHash = keccak256(bytes(vars.handle));
        require(!_exists(_profileIdByHandleHash[handleHash]), "Handle taken");

        // TODO: unchecked
        uint256 profileId = ++_totalCount;
        _mint(to, profileId);
        _profileById[profileId] = DataTypes.ProfileStruct({
            handle: vars.handle,
            imageURI: vars.imageURI
        });

        _profileIdByHandleHash[handleHash] = profileId;
        return profileId;
    }

    function getHandle(uint256 profileId) public view returns (string memory) {
        // TODO: maybe remove this check
        require(_exists(profileId), "ERC721: invalid token ID");
        return _profileById[profileId].handle;
    }

    function getProfileIdByHandle(string calldata handle)
        public
        view
        returns (uint256)
    {
        bytes32 handleHash = keccak256(bytes(handle));
        return _profileIdByHandleHash[handleHash];
    }

    function _validateHandle(string memory handle) internal pure {
        bytes memory byteHandle = bytes(handle);
        require(
            byteHandle.length <= Constants.MAX_HANDLE_LENGTH &&
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
}
