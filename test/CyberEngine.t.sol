// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./utils/MockEngine.sol";
import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/libraries/Constants.sol";
import "solmate/auth/authorities/RolesAuthority.sol";
import { Authority } from "solmate/auth/Auth.sol";
import { DataTypes } from "../src/libraries/DataTypes.sol";
import { ECDSA } from "../src/dependencies/openzeppelin/ECDSA.sol";

contract CyberEngineTest is Test {
    MockEngine internal engine;
    RolesAuthority internal rolesAuthority;
    address constant alice = address(0xA11CE);
    address constant profileAddr = address(0xB11CE);
    address constant boxAddr = address(0xC11CE);
    address constant bob = address(0xB0B);

    function setUp() public {
        rolesAuthority = new RolesAuthority(
            address(this),
            Authority(address(0))
        );
        engine = new MockEngine(
            address(this),
            profileAddr,
            boxAddr,
            rolesAuthority
        );
        rolesAuthority.setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            address(engine),
            Constants._SET_SIGNER,
            true
        );
        rolesAuthority.setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            address(engine),
            Constants._SET_PROFILE_ADDR,
            true
        );
        rolesAuthority.setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            address(engine),
            Constants._SET_BOX_ADDR,
            true
        );
        rolesAuthority.setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            address(engine),
            Constants._SET_FEE_BY_TIER,
            true
        );
        rolesAuthority.setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            address(engine),
            Constants._WITHDRAW,
            true
        );
    }

    function testBasic() public {
        assertEq(engine.profileAddress(), profileAddr);
        assertEq(engine.boxAddress(), boxAddr);
    }

    function testAuth() public {
        assertEq(address(engine.authority()), address(rolesAuthority));
    }

    function testCannotSetSignerAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(address(0));
        engine.setSigner(alice);
    }

    function testCannotSetProfileAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(address(0));
        engine.setProfileAddress(alice);
    }

    function testCannotSetBoxAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(address(0));
        engine.setBoxAddress(alice);
    }

    function testCannotSetFeeAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(address(0));
        engine.setFeeByTier(CyberEngine.Tier.Tier0, 1);
    }

    function testSetSignerAsGov() public {
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.prank(alice);
        engine.setSigner(alice);
    }

    function testSetProfileAsGov() public {
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.prank(alice);
        engine.setProfileAddress(alice);
    }

    function testSetBoxGov() public {
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.prank(alice);
        engine.setBoxAddress(alice);
    }

    function testSetFeeGov() public {
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.prank(alice);
        engine.setFeeByTier(CyberEngine.Tier.Tier0, 1);
        assertEq(engine.getFeeByTier(CyberEngine.Tier.Tier0), 1);
    }

    function testVerify() public {
        // set charlie as signer
        address charlie = vm.addr(1);
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.prank(alice);
        engine.setSigner(charlie);

        // change block timestamp to make deadline valid
        vm.warp(50);
        uint256 deadline = 100;

        string memory handle = "bob_handle";
        bytes32 digest = engine.hashTypedDataV4(
            keccak256(abi.encode(Constants._REGISTER, bob, handle, deadline))
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);
        engine.verifySignature(
            bob,
            handle,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
    }

    function testCannotVerifyAsNonSigner() public {
        // change block timestamp to make deadline valid
        vm.warp(50);
        uint256 deadline = 100;

        string memory handle = "bob_handle";
        bytes32 digest = engine.hashTypedDataV4(
            keccak256(abi.encode(Constants._REGISTER, bob, handle, deadline))
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);

        vm.expectRevert("Invalid signature");
        engine.verifySignature(
            bob,
            handle,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
    }

    function testCannotVerifyDeadlinePassed() public {
        // change block timestamp to make deadline invalid
        vm.warp(150);
        uint256 deadline = 100;

        string memory handle = "bob_handle";
        bytes32 digest = engine.hashTypedDataV4(
            keccak256(abi.encode(Constants._REGISTER, bob, handle, deadline))
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);

        vm.expectRevert("Deadline expired");
        engine.verifySignature(
            bob,
            handle,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
    }

    function testCannotVerifyInvalidSig() public {
        // set charlie as signer
        address charlie = vm.addr(1);
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.prank(alice);
        engine.setSigner(charlie);

        // change block timestamp to make deadline valid
        vm.warp(50);
        uint256 deadline = 100;

        string memory handle = "bob_handle";
        bytes32 digest = engine.hashTypedDataV4(
            keccak256(abi.encode(Constants._REGISTER, bob, handle, deadline))
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);

        // charlie signed the handle to bob, but verifies with a different address(alice).
        vm.expectRevert("Invalid signature");
        engine.verifySignature(
            alice,
            handle,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
    }

    function testInitialFees() public {
        assertEq(
            engine.getFeeByTier(CyberEngine.Tier.Tier0),
            Constants._INITIAL_FEE_TIER0
        );
        assertEq(
            engine.getFeeByTier(CyberEngine.Tier.Tier1),
            Constants._INITIAL_FEE_TIER1
        );
        assertEq(
            engine.getFeeByTier(CyberEngine.Tier.Tier2),
            Constants._INITIAL_FEE_TIER2
        );
        assertEq(
            engine.getFeeByTier(CyberEngine.Tier.Tier3),
            Constants._INITIAL_FEE_TIER3
        );
        assertEq(
            engine.getFeeByTier(CyberEngine.Tier.Tier4),
            Constants._INITIAL_FEE_TIER4
        );
        assertEq(
            engine.getFeeByTier(CyberEngine.Tier.Tier5),
            Constants._INITIAL_FEE_TIER5
        );
    }

    function testRequireEnoughFeeTier0() public view {
        engine.requireEnoughFee("A", Constants._INITIAL_FEE_TIER0);
    }

    function testCannotMeetFeeRequirement0() public {
        vm.expectRevert("Insufficient fee");
        engine.requireEnoughFee("A", Constants._INITIAL_FEE_TIER0 - 1);
    }

    function testRequireEnoughFeeTier1() public view {
        engine.requireEnoughFee("AB", Constants._INITIAL_FEE_TIER1);
    }

    function testCannotMeetFeeRequirement1() public {
        vm.expectRevert("Insufficient fee");
        engine.requireEnoughFee("AB", Constants._INITIAL_FEE_TIER1 - 1);
    }

    function testRequireEnoughFeeTier2() public view {
        engine.requireEnoughFee("ABC", Constants._INITIAL_FEE_TIER2);
    }

    function testCannotMeetFeeRequirement2() public {
        vm.expectRevert("Insufficient fee");
        engine.requireEnoughFee("ABC", Constants._INITIAL_FEE_TIER2 - 1);
    }

    function testRequireEnoughFeeTier3() public view {
        engine.requireEnoughFee("ABCD", Constants._INITIAL_FEE_TIER3);
    }

    function testCannotMeetFeeRequirement3() public {
        vm.expectRevert("Insufficient fee");
        engine.requireEnoughFee("ABCD", Constants._INITIAL_FEE_TIER3 - 1);
    }

    function testRequireEnoughFeeTier4() public view {
        engine.requireEnoughFee("ABCDE", Constants._INITIAL_FEE_TIER4);
    }

    function testCannotMeetFeeRequirement4() public {
        vm.expectRevert("Insufficient fee");
        engine.requireEnoughFee("ABCDE", Constants._INITIAL_FEE_TIER4 - 1);
    }

    function testRequireEnoughFeeTier5() public view {
        engine.requireEnoughFee("ABCDEFG", Constants._INITIAL_FEE_TIER5);
    }

    function testCannotMeetFeeRequirement5() public {
        vm.expectRevert("Insufficient fee");
        engine.requireEnoughFee("ABCDEFG", Constants._INITIAL_FEE_TIER5 - 1);
    }

    function testWithdraw() public {
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.deal(address(engine), 2);
        assertEq(address(engine).balance, 2);
        assertEq(alice.balance, 0);

        vm.prank(alice);
        engine.withdraw(alice, 1);
        assertEq(address(engine).balance, 1);
        assertEq(alice.balance, 1);
    }

    function testCannotWithdrawInsufficientBal() public {
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.prank(alice);

        vm.expectRevert("Insufficient balance");
        engine.withdraw(alice, 1);
    }

    function testCannotWithdrawAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(address(0));
        engine.withdraw(alice, 1);
    }
}
