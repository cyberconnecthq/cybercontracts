// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";

import { LibDeploy } from "../../../../script/libraries/LibDeploy.sol";
import { Constants } from "../../../../src/libraries/Constants.sol";
import { DataTypes } from "../../../../src/libraries/DataTypes.sol";

import { TestLibFixture } from "../../../utils/TestLibFixture.sol";
import { PermissionedFeeCreationMw } from "../../../../src/middlewares/profile/PermissionedFeeCreationMw.sol";
import { TestIntegrationBase } from "../../../utils/TestIntegrationBase.sol";

contract PermissionedFeeCreationMwTest is TestIntegrationBase {
    // uint256 bobProfileId;
    // address profileDescriptorAddress;
    // SubscribeOnlyOnceMw subMw;
    // event Transfer(
    //     address indexed from,
    //     address indexed to,
    //     uint256 indexed id
    // );
    // function setUp() public {
    //     _setUp();
    //     subMw = new SubscribeOnlyOnceMw();
    //     vm.label(address(subMw), "SubscribeMiddleware");
    //     string memory handle = "bob";
    //     address to = bob;
    //     bobProfileId = TestLibFixture.registerBobProfile(
    //         vm,
    //         profile,
    //         profileMw,
    //         handle,
    //         to,
    //         link3SignerPk
    //     );
    //     engine.allowSubscribeMw(address(subMw), true);
    //     vm.prank(bob);
    //     profile.setSubscribeMw(bobProfileId, address(subMw), new bytes(0));
    // }
    // function testSubscribeOnlyOnce() public {
    //     uint256[] memory ids = new uint256[](1);
    //     ids[0] = bobProfileId;
    //     bytes[] memory data = new bytes[](1);
    //     uint256 nonce = vm.getNonce(address(profile));
    //     address subscribeProxy = LibDeploy._calcContractAddress(
    //         address(profile),
    //         nonce
    //     );
    //     // TODO
    //     // vm.expectEmit(true, true, false, true);
    //     // emit DeploySubscribeNFT(bobProfileId, address(subscribeProxy));
    //     // vm.expectEmit(true, true, true, true);
    //     // emit Transfer(address(0), alice, 1);
    //     // vm.expectEmit(true, false, false, true);
    //     // emit Subscribe(alice, ids, data, data);
    //     vm.prank(alice);
    //     profile.subscribe(DataTypes.SubscribeParams(ids), data, data);
    //     // Second subscribe will fail
    //     vm.expectRevert("Already subscribed");
    //     vm.prank(alice);
    //     profile.subscribe(DataTypes.SubscribeParams(ids), data, data);
    // }
    // function testCannotCreateProfileWithAnInvalidCharacter() public {
    //     vm.expectRevert("HANDLE_INVALID_CHARACTER");
    //     token.createProfile(
    //         DataTypes.CreateProfileParams(
    //             alice,
    //             "alice&bob",
    //             imageUri,
    //             "metadata"
    //         )
    //     );
    // }
    // function testCannotCreateProfileWith0LenthHandle() public {
    //     vm.expectRevert("HANDLE_INVALID_LENGTH");
    //     token.createProfile(
    //         DataTypes.CreateProfileParams(alice, "", imageUri, "metadata")
    //     );
    // }
    // function testCannotCreateProfileWithACapitalLetter() public {
    //     vm.expectRevert("HANDLE_INVALID_CHARACTER");
    //     token.createProfile(
    //         DataTypes.CreateProfileParams(alice, "Test", imageUri, "metadata")
    //     );
    // }
    // function testCannotCreateProfileWithBlankSpace() public {
    //     vm.expectRevert("HANDLE_INVALID_CHARACTER");
    //     token.createProfile(
    //         DataTypes.CreateProfileParams(alice, " ", imageUri, "metadata")
    //     );
    // }
    // function testCannotCreateProfileLongerThanMaxHandleLength() public {
    //     vm.expectRevert("HANDLE_INVALID_LENGTH");
    //     token.createProfile(
    //         DataTypes.CreateProfileParams(
    //             alice,
    //             "aliceandbobisareallylongname",
    //             "https://example.com/alice.jpg",
    //             "metadata"
    //         )
    //     );
    // }
    // function testCannotSetSignerAsNonGov() public {
    //     vm.expectRevert("UNAUTHORIZED");
    //     vm.prank(alice);
    //     profile.setSigner(alice);
    // }
    // function testCannotSetFeeAsNonGov() public {
    //     vm.expectRevert("UNAUTHORIZED");
    //     vm.prank(alice);
    //     profile.setFeeByTier(DataTypes.Tier.Tier0, 1);
    // }
    // function testSetSignerAsGov() public {
    //     rolesAuthority.setUserRole(alice, Constants._PROFILE_GOV_ROLE, true);
    //     vm.prank(alice);
    //     vm.expectEmit(true, true, false, true);
    //     emit SetSigner(address(0), alice);
    //     profile.setSigner(alice);
    // }
    // function testSetFeeGov() public {
    //     rolesAuthority.setUserRole(alice, Constants._PROFILE_GOV_ROLE, true);
    //     vm.prank(alice);
    //     vm.expectEmit(true, true, true, true);
    //     emit SetFeeByTier(
    //         DataTypes.Tier.Tier0,
    //         Constants._INITIAL_FEE_TIER0,
    //         1
    //     );
    //     profile.setFeeByTier(DataTypes.Tier.Tier0, 1);
    //     assertEq(profile.feeMapping(DataTypes.Tier.Tier0), 1);
    // }
    // function testVerify() public {
    //     // set charlie as signer
    //     address charlie = vm.addr(1);
    //     rolesAuthority.setUserRole(alice, Constants._PROFILE_GOV_ROLE, true);
    //     vm.prank(alice);
    //     profile.setSigner(charlie);
    //     // change block timestamp to make deadline valid
    //     vm.warp(50);
    //     uint256 deadline = 100;
    //     bytes32 digest = profile.hashTypedDataV4(
    //         keccak256(
    //             abi.encode(
    //                 Constants._CREATE_PROFILE_TYPEHASH,
    //                 bob,
    //                 keccak256(bytes(handle)),
    //                 keccak256(bytes(avatar)),
    //                 keccak256(bytes(metadata)),
    //                 0,
    //                 deadline
    //             )
    //         )
    //     );
    //     (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);
    //     profile.verifySignature(
    //         digest,
    //         DataTypes.EIP712Signature(v, r, s, deadline)
    //     );
    // }
    // function testCannotVerifyAsNonSigner() public {
    //     // change block timestamp to make deadline valid
    //     vm.warp(50);
    //     uint256 deadline = 100;
    //     bytes32 digest = profile.hashTypedDataV4(
    //         keccak256(
    //             abi.encode(
    //                 Constants._CREATE_PROFILE_TYPEHASH,
    //                 bob,
    //                 keccak256(bytes(handle)),
    //                 keccak256(bytes(avatar)),
    //                 keccak256(bytes(metadata)),
    //                 0,
    //                 deadline
    //             )
    //         )
    //     );
    //     (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);
    //     vm.expectRevert("INVALID_SIGNATURE");
    //     profile.verifySignature(
    //         digest,
    //         DataTypes.EIP712Signature(v, r, s, deadline)
    //     );
    // }
    // function testCannotVerifyDeadlinePassed() public {
    //     // change block timestamp to make deadline invalid
    //     vm.warp(150);
    //     uint256 deadline = 100;
    //     bytes32 digest = profile.hashTypedDataV4(
    //         keccak256(
    //             abi.encode(
    //                 Constants._CREATE_PROFILE_TYPEHASH,
    //                 bob,
    //                 keccak256(bytes(handle)),
    //                 keccak256(bytes(avatar)),
    //                 keccak256(bytes(metadata)),
    //                 0,
    //                 deadline
    //             )
    //         )
    //     );
    //     (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);
    //     vm.expectRevert("DEADLINE_EXCEEDED");
    //     profile.verifySignature(
    //         digest,
    //         DataTypes.EIP712Signature(v, r, s, deadline)
    //     );
    // }
    // function testInitialFees() public {
    //     assertEq(
    //         profile.feeMapping(DataTypes.Tier.Tier0),
    //         Constants._INITIAL_FEE_TIER0
    //     );
    //     assertEq(
    //         profile.feeMapping(DataTypes.Tier.Tier1),
    //         Constants._INITIAL_FEE_TIER1
    //     );
    //     assertEq(
    //         profile.feeMapping(DataTypes.Tier.Tier2),
    //         Constants._INITIAL_FEE_TIER2
    //     );
    //     assertEq(
    //         profile.feeMapping(DataTypes.Tier.Tier3),
    //         Constants._INITIAL_FEE_TIER3
    //     );
    //     assertEq(
    //         profile.feeMapping(DataTypes.Tier.Tier4),
    //         Constants._INITIAL_FEE_TIER4
    //     );
    //     assertEq(
    //         profile.feeMapping(DataTypes.Tier.Tier5),
    //         Constants._INITIAL_FEE_TIER5
    //     );
    // }
    // function testRequireEnoughFeeTier0() public view {
    //     profile.requireEnoughFee("A", Constants._INITIAL_FEE_TIER0);
    // }
    // function testCannotMeetFeeRequirement0() public {
    //     vm.expectRevert("INSUFFICIENT_FEE");
    //     profile.requireEnoughFee("A", Constants._INITIAL_FEE_TIER0 - 1);
    // }
    // function testRequireEnoughFeeTier1() public view {
    //     profile.requireEnoughFee("AB", Constants._INITIAL_FEE_TIER1);
    // }
    // function testCannotMeetFeeRequirement1() public {
    //     vm.expectRevert("INSUFFICIENT_FEE");
    //     profile.requireEnoughFee("AB", Constants._INITIAL_FEE_TIER1 - 1);
    // }
    // function testRequireEnoughFeeTier2() public view {
    //     profile.requireEnoughFee("ABC", Constants._INITIAL_FEE_TIER2);
    // }
    // function testCannotMeetFeeRequirement2() public {
    //     vm.expectRevert("INSUFFICIENT_FEE");
    //     profile.requireEnoughFee("ABC", Constants._INITIAL_FEE_TIER2 - 1);
    // }
    // function testRequireEnoughFeeTier3() public view {
    //     profile.requireEnoughFee("ABCD", Constants._INITIAL_FEE_TIER3);
    // }
    // function testCannotMeetFeeRequirement3() public {
    //     vm.expectRevert("INSUFFICIENT_FEE");
    //     profile.requireEnoughFee("ABCD", Constants._INITIAL_FEE_TIER3 - 1);
    // }
    // function testRequireEnoughFeeTier4() public view {
    //     profile.requireEnoughFee("ABCDE", Constants._INITIAL_FEE_TIER4);
    // }
    // function testCannotMeetFeeRequirement4() public {
    //     vm.expectRevert("INSUFFICIENT_FEE");
    //     profile.requireEnoughFee("ABCDE", Constants._INITIAL_FEE_TIER4 - 1);
    // }
    // function testRequireEnoughFeeTier5() public view {
    //     profile.requireEnoughFee("ABCDEFG", Constants._INITIAL_FEE_TIER5);
    // }
    // function testCannotMeetFeeRequirement5() public {
    //     vm.expectRevert("INSUFFICIENT_FEE");
    //     profile.requireEnoughFee("ABCDEFG", Constants._INITIAL_FEE_TIER5 - 1);
    // }
    // TODO test treasury
    // function testRegister() public {
    //     address charlie = vm.addr(1);
    //     rolesAuthority.setUserRole(alice, Constants._PROFILE_GOV_ROLE, true);
    //     vm.prank(alice);
    //     profile.setSigner(charlie);
    //     // change block timestamp to make deadline valid
    //     vm.warp(50);
    //     uint256 deadline = 100;
    //     bytes32 digest = profile.hashTypedDataV4(
    //         keccak256(
    //             abi.encode(
    //                 Constants._CREATE_PROFILE_TYPEHASH,
    //                 bob,
    //                 keccak256(bytes(handle)),
    //                 keccak256(bytes(avatar)),
    //                 keccak256(bytes(metadata)),
    //                 0,
    //                 deadline
    //             )
    //         )
    //     );
    //     (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);
    //     assertEq(profile.nonces(bob), 0);
    //     vm.expectEmit(true, true, true, true);
    //     emit Transfer(address(0), bob, 1);
    //     vm.expectEmit(true, true, false, true);
    //     emit SetPrimaryProfile(bob, 1);
    //     vm.expectEmit(true, true, false, true);
    //     emit Register(bob, 1, handle, avatar, metadata);
    //     assertEq(
    //         profile.createProfile{ value: Constants._INITIAL_FEE_TIER2 }(
    //             DataTypes.CreateProfileParams(bob, handle, avatar, metadata),
    //             DataTypes.EIP712Signature(v, r, s, deadline)
    //         ),
    //         1
    //     );
    //     assertEq(profile.nonces(bob), 1);
    // }
    // function testCannotRegisterInvalidSig() public {
    //     // set charlie as signer
    //     address charlie = vm.addr(1);
    //     rolesAuthority.setUserRole(alice, Constants._PROFILE_GOV_ROLE, true);
    //     vm.prank(alice);
    //     profile.setSigner(charlie);
    //     // change block timestamp to make deadline valid
    //     vm.warp(50);
    //     uint256 deadline = 100;
    //     bytes32 digest = profile.hashTypedDataV4(
    //         keccak256(
    //             abi.encode(
    //                 Constants._CREATE_PROFILE_TYPEHASH,
    //                 bob,
    //                 keccak256(bytes(handle)),
    //                 keccak256(bytes(avatar)),
    //                 keccak256(bytes(metadata)),
    //                 0,
    //                 deadline
    //             )
    //         )
    //     );
    //     (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);
    //     // charlie signed the handle to bob, but register with a different address(alice).
    //     vm.expectRevert("INVALID_SIGNATURE");
    //     profile.createProfile{ value: Constants._INITIAL_FEE_TIER2 }(
    //         DataTypes.CreateProfileParams(alice, handle, avatar, metadata),
    //         DataTypes.EIP712Signature(v, r, s, deadline)
    //     );
    // }
    // function testCannotRegisterReplay() public {
    //     // set charlie as signer
    //     address charlie = vm.addr(1);
    //     rolesAuthority.setUserRole(alice, Constants._PROFILE_GOV_ROLE, true);
    //     vm.prank(alice);
    //     profile.setSigner(charlie);
    //     // change block timestamp to make deadline valid
    //     vm.warp(50);
    //     uint256 deadline = 100;
    //     bytes32 digest = profile.hashTypedDataV4(
    //         keccak256(
    //             abi.encode(
    //                 Constants._CREATE_PROFILE_TYPEHASH,
    //                 bob,
    //                 keccak256(bytes(handle)),
    //                 keccak256(bytes(avatar)),
    //                 keccak256(bytes(metadata)),
    //                 0,
    //                 deadline
    //             )
    //         )
    //     );
    //     (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);
    //     profile.createProfile{ value: Constants._INITIAL_FEE_TIER2 }(
    //         DataTypes.CreateProfileParams(bob, handle, avatar, metadata),
    //         DataTypes.EIP712Signature(v, r, s, deadline)
    //     );
    //     vm.expectRevert("INVALID_SIGNATURE");
    //     profile.createProfile{ value: Constants._INITIAL_FEE_TIER2 }(
    //         DataTypes.CreateProfileParams(bob, handle, avatar, metadata),
    //         DataTypes.EIP712Signature(v, r, s, deadline)
    //     );
    // }
}
