pragma solidity 0.8.14;

import {CyberNFTBase} from "../../src/CyberNFTBase.sol";

contract MockNFT is CyberNFTBase {
    constructor(string memory _name, string memory _symbol)
        CyberNFTBase(_name, _symbol)
    {}

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
}
