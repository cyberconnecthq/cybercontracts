// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "../src/BoxNFT.sol";
import "forge-std/Test.sol";
import "../src/libraries/Constants.sol";
import { RolesAuthority } from "../src/dependencies/solmate/RolesAuthority.sol";
import { Authority } from "../src/dependencies/solmate/Auth.sol";

contract BoxNFTTest is Test {
    BoxNFT internal token;
    address constant alice = address(0xA11CE);
    address constant engine = address(0xe);

    function setUp() public {
        token = new BoxNFT(engine);
        token.initialize("TestBox", "TB");
    }

    function testBasic() public {
        assertEq(token.name(), "TestBox");
        assertEq(token.symbol(), "TB");
    }

    function testAuth() public {
        assertEq(address(token.ENGINE()), engine);
    }

    function testBalanceIncremented() public {
        vm.startPrank(engine);
        address bob = address(0xB0B);
        token.mint(alice);
        token.mint(bob);
        assertEq(token.totalSupply(), 2);
    }

    function testCannotMintAsNonEngine() public {
        vm.expectRevert("Only Engine");
        vm.prank(address(0));
        token.mint(address(0));
    }

    function testMintAsEngine() public {
        vm.prank(engine);
        token.mint(alice);
        assertEq(token.balanceOf(alice), 1);
    }
}
