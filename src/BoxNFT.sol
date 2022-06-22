// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { IBoxNFT } from "./interfaces/IBoxNFT.sol";
import { CyberNFTBase } from "./base/CyberNFTBase.sol";
import { RolesAuthority } from "./base/RolesAuthority.sol";

contract BoxNFT is CyberNFTBase, IBoxNFT {
    address public immutable ENGINE;

    // ENGINE for mint
    constructor(address _engine) {
        require(_engine != address(0), "Engine address cannot be 0");
        ENGINE = _engine;
    }

    function initialize(string calldata _name, string calldata _symbol)
        external
        initializer
    {
        CyberNFTBase._initialize(_name, _symbol);
    }

    function mint(address _to) external returns (uint256) {
        require(msg.sender == address(ENGINE), "Only Engine could mint");
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
