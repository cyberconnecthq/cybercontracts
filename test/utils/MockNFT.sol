// SPDX-License-Identifier: MIT

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

    function mint(address _to) public {
        super._mint(_to);
    }

    function initialize(string calldata _name, string calldata _symbol)
        external
        initializer
    {
        super._initialize(_name, _symbol);
    }
}
