// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { CyberNFTBase } from "./base/CyberNFTBase.sol";
import { RolesAuthority } from "./base/RolesAuthority.sol";
import { Auth } from "./base/Auth.sol";

contract BoxNFT is CyberNFTBase, Auth {
    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _owner,
        RolesAuthority _rolesAuthority
    ) external initializer {
        CyberNFTBase._initialize(_name, _symbol);
        Auth.__Auth_Init(_owner, _rolesAuthority);
    }

    function initialize(string calldata _name, string calldata _symbol)
        external
        initializer
    {
        super._initialize(_name, _symbol);
    }

    function mint(address _to) public requiresAuth {
        super._mint(_to);
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
