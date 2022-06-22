// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { IBoxNFT } from "./interfaces/IBoxNFT.sol";
import { CyberNFTBase } from "./base/CyberNFTBase.sol";
import { RolesAuthority } from "./base/RolesAuthority.sol";
import { Auth } from "./base/Auth.sol";

contract BoxNFT is CyberNFTBase, Auth, IBoxNFT {
    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _owner,
        RolesAuthority _rolesAuthority
    ) external initializer {
        CyberNFTBase._initialize(_name, _symbol);
        Auth.__Auth_Init(_owner, _rolesAuthority);
    }

    function mint(address _to) external requiresAuth returns (uint256) {
        super._mint(_to);
        return _totalCount;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        return "";
    }
}
