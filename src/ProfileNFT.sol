pragma solidity 0.8.14;

import "./CyberNFTBase.sol";
import "solmate/auth/authorities/RolesAuthority.sol";
import {Authority} from "solmate/auth/Auth.sol";
import {Constants} from "./libraries/Constants.sol";
import {DataTypes} from "./libraries/DataTypes.sol";
import {LibString} from "./libraries/LibString.sol";
import {Base64} from "./libraries/Base64.sol";

// TODO: Owner cannot be set with conflicting role for capacity
contract ProfileNFT is CyberNFTBase, RolesAuthority {
    mapping(uint256 => DataTypes.ProfileStruct) internal _profileById;
    mapping(bytes32 => uint256) internal _profileIdByHandleHash;

    constructor(
        string memory _name,
        string memory _symbol,
        address _owner
    ) CyberNFTBase(_name, _symbol) RolesAuthority(_owner, this) {}

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

    function setMinterRole(address minter, bool enabled) external requiresAuth {
        setUserRole(minter, Constants.MINTER_ROLE, enabled);
    }

    function createProfile(DataTypes.CreateProfileData calldata vars)
        external
        requiresAuth
        returns (uint256)
    {
        bytes32 handleHash = keccak256(bytes(vars.handle));
        require(!_exists(_profileIdByHandleHash[handleHash]), "Handle taken");

        // TODO: unchecked
        uint256 profileId = ++_totalCount;
        _mint(vars.to, profileId);
        _profileById[profileId] = DataTypes.ProfileStruct({
            subscribeNFT: vars.subscribeNFT,
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
}
