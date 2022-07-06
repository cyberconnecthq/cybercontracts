// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "forge-std/Test.sol";
import "./utils/MockNFT.sol";

contract CyberNFTBaseTest is Test {
    MockNFT internal token;

    function setUp() public {
        token = new MockNFT();
        token.initialize("TestNFT", "TNFT");
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
    
    // should return token ID, should increment everytime we call
    function testReturnTokenId() public {
        assertEq(token.mint(msg.sender), 1);
        assertEq(token.mint(msg.sender), 2);
        assertEq(token.mint(msg.sender), 3);
    }


}
