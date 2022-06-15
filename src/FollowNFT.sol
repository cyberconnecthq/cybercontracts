// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./base/CyberNFTBase.sol";

contract FollowNFT is CyberNFTBase {
    // constructor(
    //     string memory _name,
    //     string memory _symbol,
    //     address _owner,
    //     RolesAuthority _rolesAuthority
    // ) CyberNFTBase(_name, _symbol) Auth(_owner, _rolesAuthority) {}

    // constructor(address beacon) {

    // }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        return "";
    }

    function mint(address _to) public {
        super._mint(_to);
    }
}
