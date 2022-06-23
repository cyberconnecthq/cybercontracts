// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { IProfileNFT } from "./interfaces/IProfileNFT.sol";
import { CyberNFTBase } from "./base/CyberNFTBase.sol";
import { RolesAuthority } from "./base/RolesAuthority.sol";
import { Auth } from "./base/Auth.sol";
import { Constants } from "./libraries/Constants.sol";
import { DataTypes } from "./libraries/DataTypes.sol";
import { LibString } from "./libraries/LibString.sol";
import { Base64 } from "./dependencies/openzeppelin/Base64.sol";
import { ErrorMessages } from "./libraries/ErrorMessages.sol";

// TODO: Owner cannot be set with conflicting role for capacity
contract ProfileNFT is CyberNFTBase, Auth, IProfileNFT {
    mapping(uint256 => DataTypes.ProfileStruct) internal _profileById;
    mapping(bytes32 => uint256) internal _profileIdByHandleHash;

    // TODO: enable this, currently disabled for better testability
    // constructor() {
    //     _disableInitializers();
    // }

    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _owner,
        RolesAuthority _rolesAuthority
    ) external initializer {
        CyberNFTBase._initialize(_name, _symbol);
        Auth.__Auth_Init(_owner, _rolesAuthority);
    }

    function createProfile(address to, DataTypes.ProfileStruct calldata vars)
        external
        requiresAuth
        returns (uint256)
    {
        _validateHandle(vars.handle);

        bytes32 handleHash = keccak256(bytes(vars.handle));
        require(
            !_exists(_profileIdByHandleHash[handleHash]),
            ErrorMessages._PROFILE_HANDLE_TAKEN
        );

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
        require(_exists(profileId), ErrorMessages._TOKEN_ID_INVALID);
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

    function _validateHandle(string calldata handle) internal pure {
        bytes memory byteHandle = bytes(handle);
        require(
            byteHandle.length <= Constants._MAX_HANDLE_LENGTH &&
                byteHandle.length > 0,
            ErrorMessages._PROFILE_HANDLE_INVALID_LENGTH
        );

        uint256 byteHandleLength = byteHandle.length;
        for (uint256 i = 0; i < byteHandleLength; ) {
            bytes1 b = byteHandle[i];
            require(
                (b >= "0" && b <= "9") || (b >= "a" && b <= "z") || b == "_",
                ErrorMessages._PROFILE_HANDLE_INVALID_CHAR
            );
            // optimation
            unchecked {
                ++i;
            }
        }
    }
}
