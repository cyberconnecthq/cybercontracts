// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/CyberNFTBase.sol";

contract CyberNFTBaseTest is Test {
    CyberNFTBase internal token;

    function setUp() public {
        token = new CyberNFTBase("TestNFT", "TNFT");
    }

    function testBasic() public {
        assertEq(token.name(), "TestNFT");
        assertEq(token.symbol(), "TNFT");
    }
}
