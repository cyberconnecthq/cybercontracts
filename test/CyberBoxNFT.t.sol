// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "../src/periphery/CyberBoxNFT.sol";
import "forge-std/Test.sol";
import "../src/libraries/Constants.sol";
import { RolesAuthority } from "../src/dependencies/solmate/RolesAuthority.sol";
import { Authority } from "../src/dependencies/solmate/Auth.sol";
import { ICyberBoxEvents } from "../src/interfaces/ICyberBoxEvents.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { TestLib712 } from "./utils/TestLib712.sol";

contract BoxNFTTest is Test, ICyberBoxEvents {
    CyberBoxNFT internal token;
    address constant alice = address(0xA11CE);
    address constant bob = address(0xB0B);
    address constant owner = address(0xe);

    function setUp() public {
        CyberBoxNFT impl = new CyberBoxNFT();
        bytes memory data = abi.encodeWithSelector(
            CyberBoxNFT.initialize.selector,
            owner,
            "TestBox",
            "TB"
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), data);
        token = CyberBoxNFT(address(proxy));
    }

    function testBasic() public {
        assertEq(token.name(), "TestBox");
        assertEq(token.symbol(), "TB");
        assertEq(token.paused(), true);
    }

    function testCannotSetSignerNonOwner() public {
        vm.expectRevert("Only Owner");
        vm.prank(address(0));
        token.setSigner(alice);
    }

    function testCannotSetOwnerNonOwner() public {
        vm.expectRevert("Only Owner");
        vm.prank(address(0));
        token.setSigner(alice);
    }

    function testSetSignerNonOwner() public {
        vm.prank(owner);

        vm.expectEmit(true, true, false, true);
        emit SetSigner(owner, alice);
        token.setSigner(alice);
    }

    function testSetOwnerNonOwner() public {
        vm.prank(owner);

        vm.expectEmit(true, true, false, true);
        emit SetOwner(owner, alice);
        token.setOwner(alice);
    }

    // set prank as non engine, then try to pause, should be reverted
    function testCannotPauseFromNonOwner() public {
        vm.expectRevert("Only Owner");
        vm.prank(address(0));
        token.pause(true);
    }

    // set prank as owner, then try to pause again, since it was paused already(from initialization), it can't pause again
    function testCannotPauseWhenAlreadyPaused() public {
        vm.prank(owner);
        vm.expectRevert("Pausable: paused");
        token.pause(true);
    }

    // we first unpause, verify, then we unpause, then verify, we can't unpause when already unpaused
    function testCannotUnpauseWhenAlreadyUnpaused() public {
        vm.startPrank(owner);
        token.pause(false);
        vm.expectRevert("Pausable: not paused");
        token.pause(false);
    }

    // we first unpause, verify, then we unpause, then verify
    function testPause() public {
        vm.startPrank(owner);
        token.pause(false);
        assertEq(token.paused(), false);
        token.pause(true);
        assertEq(token.paused(), true);
    }

    // we first verify that the contracy is paused, then unpause, and verify
    function testUnpause() public {
        vm.startPrank(owner);
        assertEq(token.paused(), true);
        token.pause(false);
        assertEq(token.paused(), false);
    }

    function testClaimBox() public {
        address charlie = vm.addr(1);
        vm.prank(owner);
        token.setSigner(charlie);

        // change block timestamp to make deadline valid
        vm.warp(50);
        uint256 deadline = 100;
        bytes32 digest = TestLib712.hashTypedDataV4(
            address(token),
            keccak256(
                abi.encode(Constants._CLAIM_BOX_TYPEHASH, bob, 0, deadline)
            ),
            "TestBox",
            "1"
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);
        assertEq(token.nonces(bob), 0);

        vm.expectEmit(true, true, false, true);
        emit ClaimBox(bob, 1);

        assertEq(
            token.claimBox(bob, DataTypes.EIP712Signature(v, r, s, deadline)),
            1
        );
        assertEq(token.nonces(bob), 1);
        assertEq(token.totalSupply(), 1);
    }

    function testCannotClaimInvalidSig() public {
        // set charlie as signer
        address charlie = vm.addr(1);
        vm.prank(owner);
        token.setSigner(charlie);

        // change block timestamp to make deadline valid
        vm.warp(50);
        uint256 deadline = 100;
        bytes32 digest = TestLib712.hashTypedDataV4(
            address(token),
            keccak256(
                abi.encode(Constants._CLAIM_BOX_TYPEHASH, bob, 0, deadline)
            ),
            "TestBox",
            "1"
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);

        // charlie signed the box to bob, but register with a different address(alice).
        vm.expectRevert("Invalid signature");
        token.claimBox(alice, DataTypes.EIP712Signature(v, r, s, deadline));
    }
}
