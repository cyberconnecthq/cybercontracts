// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";

import { Constants } from "../../src/libraries/Constants.sol";
import { DataTypes } from "../../src/libraries/DataTypes.sol";

import { TestLib712 } from "../utils/TestLib712.sol";
import { MockERC20 } from "../utils/MockERC20.sol";
import { CyberVault } from "../../src/periphery/CyberVault.sol";

contract CyberVaultTest is Test {
    event Initialize(address indexed owner);
    event Claim(
        uint256 indexed profileId,
        address indexed to,
        address indexed currency,
        uint256 amount
    );
    event Deposit(
        uint256 indexed profileId,
        address indexed currency,
        uint256 indexed amount
    );
    event SetSigner(address indexed preSigner, address indexed newSigner);

    CyberVault internal vault;
    MockERC20 internal token;
    address constant signer = address(0xA11CE);
    address constant owner = address(0xe);
    address constant bob = address(0xB0B);

    function setUp() public {
        vault = new CyberVault(owner);
        token = new MockERC20("Test Coin", "TC");
        token.mint(bob, 200);
    }

    function testBasic() public {
        assertEq(vault.getSigner(), owner);
    }

    function testCannotSetSignerNonOwner() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(address(0));
        vault.setSigner(signer);
    }

    function testCannotSetOwnerNonOwner() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(address(0));
        vault.setOwner(signer);
    }

    function testSetSigner() public {
        vm.prank(owner);

        vm.expectEmit(true, true, false, true);
        emit SetSigner(owner, signer);
        vault.setSigner(signer);
    }

    function testSetOwner() public {
        vm.prank(owner);
        vault.setOwner(bob);
    }

    function testDeposit() public {
        vm.startPrank(bob);
        assertEq(token.balanceOf(bob), 200);

        uint256 profileId = 1;
        uint256 amount = 50;

        token.approve(address(vault), amount);
        vault.deposit(profileId, address(token), amount);

        assertEq(token.balanceOf(bob), 200 - amount);
        assertEq(vault.balanceOf(profileId, address(token)), amount);
    }

    function testDepositInsufficientBal() public {
        vm.startPrank(bob);
        assertEq(token.balanceOf(bob), 200);

        uint256 profileId = 1;
        token.approve(address(vault), 1000);

        vm.expectRevert("INSUFFICIENT_BALANCE");
        vault.deposit(profileId, address(token), 1000);

        assertEq(token.balanceOf(bob), 200);
        assertEq(vault.balanceOf(profileId, address(token)), 0);
    }

    function testClaim() public {
        address charlie = vm.addr(1);
        vm.prank(owner);
        vault.setSigner(charlie);

        uint256 profileId = 1;
        uint256 deposit = 1000;
        uint256 claim = 300;
        uint256 bobInitBal = 200;

        token.approve(address(vault), deposit);
        vault.deposit(profileId, address(token), deposit);

        assertEq(vault.balanceOf(profileId, address(token)), deposit);
        assertEq(token.balanceOf(bob), bobInitBal);
        assertEq(vault.nonces(bob), 0);

        vm.warp(50);
        uint256 deadline = 100;
        bytes32 digest = TestLib712.hashTypedDataV4(
            address(vault),
            keccak256(
                abi.encode(
                    Constants._CLAIM_TYPEHASH,
                    profileId,
                    bob,
                    address(token),
                    claim,
                    0,
                    deadline
                )
            ),
            "CyberVault",
            "1"
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);
        vault.claim(
            profileId,
            bob,
            address(token),
            claim,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );

        assertEq(vault.balanceOf(profileId, address(token)), deposit - claim);
        assertEq(token.balanceOf(bob), bobInitBal + claim);
        assertEq(vault.nonces(bob), 1);
    }

    function testClaimInsufficientBal() public {
        address charlie = vm.addr(1);
        vm.prank(owner);
        vault.setSigner(charlie);

        uint256 profileId = 1;
        uint256 deposit = 0;
        uint256 claim = 300;
        uint256 bobInitBal = 200;

        assertEq(vault.balanceOf(profileId, address(token)), deposit);
        assertEq(token.balanceOf(bob), bobInitBal);

        vm.warp(50);
        uint256 deadline = 100;
        bytes32 digest = TestLib712.hashTypedDataV4(
            address(vault),
            keccak256(
                abi.encode(
                    Constants._CLAIM_TYPEHASH,
                    profileId,
                    bob,
                    address(token),
                    claim,
                    0,
                    deadline
                )
            ),
            "CyberVault",
            "1"
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);

        vm.expectRevert("INSUFFICIENT_BALANCE");
        vault.claim(
            profileId,
            bob,
            address(token),
            claim,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );

        assertEq(vault.balanceOf(profileId, address(token)), deposit);
        assertEq(token.balanceOf(bob), bobInitBal);
    }

    function testClaimInvalidSig() public {
        address charlie = vm.addr(1);
        vm.prank(owner);
        vault.setSigner(charlie);

        uint256 profileId = 1;
        uint256 deposit = 1000;
        uint256 claim = 300;
        uint256 bobInitBal = 200;

        token.approve(address(vault), deposit);
        vault.deposit(profileId, address(token), deposit);

        vm.warp(50);
        uint256 deadline = 100;
        bytes32 digest = TestLib712.hashTypedDataV4(
            address(vault),
            keccak256(
                abi.encode(
                    Constants._CLAIM_TYPEHASH,
                    profileId,
                    bob,
                    address(token),
                    claim + 200,
                    0,
                    deadline
                )
            ),
            "CyberVault",
            "1"
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);
        vm.expectRevert("INVALID_SIGNATURE");
        vault.claim(
            profileId,
            bob,
            address(token),
            claim,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
    }
}
