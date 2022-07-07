// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { CyberNFTBase } from "../../src/base/CyberNFTBase.sol";

contract MockNFT is CyberNFTBase {
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return "";
    }

    function mint(address _to) public returns (uint256) {
        return super._mint(_to);
    }

    function initialize(string calldata _name, string calldata _symbol)
        external
        initializer
    {
        super._initialize(_name, _symbol, "1");
    }
}
