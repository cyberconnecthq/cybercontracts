pragma solidity 0.8.14;

import "./base/CyberNFTBase.sol";
import "solmate/auth/authorities/RolesAuthority.sol";
import { Auth } from "solmate/auth/Auth.sol";

contract BoxNFT is CyberNFTBase, Auth {
    constructor(
        string memory _name,
        string memory _symbol,
        address _owner,
        RolesAuthority _rolesAuthority
    ) CyberNFTBase(_name, _symbol) Auth(_owner, _rolesAuthority) {}

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
