// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "../src/periphery/BoxNFT.sol";
import "forge-std/Test.sol";
import "../src/libraries/Constants.sol";
import { RolesAuthority } from "../src/dependencies/solmate/RolesAuthority.sol";
import { Authority } from "../src/dependencies/solmate/Auth.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract BoxNFTTest is Test {
    BoxNFT internal token;
    address constant alice = address(0xA11CE);
    address constant engine = address(0xe);

    function setUp() public {
        BoxNFT impl = new BoxNFT(engine);
        bytes memory data = abi.encodeWithSelector(
            BoxNFT.initialize.selector,
            "TestBox",
            "TB"
        );
        ERC1967Proxy engineProxy = new ERC1967Proxy(address(impl), data);
        token = BoxNFT(address(engineProxy));
    }

    function testBasic() public {
        assertEq(token.name(), "TestBox");
        assertEq(token.symbol(), "TB");
        assertEq(token.paused(), true);
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

    // set prank as non engine, then try to pause, should be reverted
    function testCannotPauseFromNonEngine() public {
        vm.expectRevert("Only Engine");
        vm.prank(address(0));
        token.pause(true);
    }

    // set prank as engine, then try to pause again, since it was paused already(from initialization), it can't pause again
    function testCannotPauseWhenAlreadyPaused() public {
        vm.prank(engine);
        vm.expectRevert("Pausable: paused");
        token.pause(true);
    }

    // we first unpause, verify, then we unpause, then verify, we can't unpause when already unpaused
    function testCannotUnpauseWhenAlreadyUnpaused() public {
        vm.startPrank(engine);
        token.pause(false);
        vm.expectRevert("Pausable: not paused");
        token.pause(false);
    }

    // we first unpause, verify, then we unpause, then verify
    function testPause() public {
        vm.startPrank(engine);
        token.pause(false);
        assertEq(token.paused(), false);
        token.pause(true);
        assertEq(token.paused(), true);
    }

    // we first verify that the contracy is paused, then unpause, and verify
    function testUnpause() public {
        vm.startPrank(engine);
        assertEq(token.paused(), true);
        token.pause(false);
        assertEq(token.paused(), false);
    }

    // should return token ID, should increment everytime we call
    function testReturnTokenId() public {
        vm.startPrank(engine);
        assertEq(token.mint(alice), 1);
        assertEq(token.mint(alice), 2);
        assertEq(token.mint(alice), 3);
    }
}
