// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "forge-std/Test.sol";
import "./utils/MockNFT.sol";

contract CyberNFTBaseTest is Test {
    MockNFT internal token;

    function setUp() public {
        token = new MockNFT("TestNFT", "TNFT");
    }

    function testBasic() public {
        assertEq(token.name(), "TestNFT");
        assertEq(token.symbol(), "TNFT");
    }

    function testInternalMint() public {
        assertEq(token.totalSupply(), 0);
        token.mint(msg.sender);
        assertEq(token.totalSupply(), 1);
        assertEq(token.balanceOf(msg.sender), 1);
    }
}
