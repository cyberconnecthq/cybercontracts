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
        engine.verify(
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
        engine.verify(
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
        engine.verify(
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
        engine.verify(
            alice,
            handle,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
    }
}
