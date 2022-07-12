// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import { MockProfile } from "./utils/MockProfile.sol";
import { Constants } from "../src/libraries/Constants.sol";
import { IProfileNFT } from "../src/interfaces/IProfileNFT.sol";
import { RolesAuthority } from "../src/dependencies/solmate/RolesAuthority.sol";
import { ProfileRoles } from "../src/core/ProfileRoles.sol";
import { ProfileNFT } from "../src/core/ProfileNFT.sol";
import { SubscribeNFT } from "../src/core/SubscribeNFT.sol";
import { UpgradeableBeacon } from "../src/upgradeability/UpgradeableBeacon.sol";
import { Authority } from "../src/dependencies/solmate/Auth.sol";
import { DataTypes } from "../src/libraries/DataTypes.sol";
import { IProfileNFTEvents } from "../src/interfaces/IProfileNFTEvents.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { LibDeploy } from "../script/libraries/LibDeploy.sol";
import { IProfileNFTDescriptor } from "../src/interfaces/IProfileNFTDescriptor.sol";
import { Link3ProfileDescriptor } from "../src/periphery/Link3ProfileDescriptor.sol";
import { TestDeployer } from "./utils/TestDeployer.sol";

contract ProfileNFTBehaviorTest is Test, IProfileNFTEvents, TestDeployer {
    MockProfile internal profile;
    RolesAuthority internal rolesAuthority;
    address internal essenceBeacon = address(0xC);
    address internal subscribeBeacon;

    address constant alice = address(0xA11CE);
    address constant bob = address(0xB0B);
    string constant handle = "handle";
    string constant handle2 = "handle2";
    string constant avatar = "avatar";
    string constant metadata = "metadata";
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );
    address descriptor = address(0x233);

    function setUp() public {
        MockProfile profileImpl = new MockProfile();
        uint256 nonce = vm.getNonce(address(this));
        address profileAddr = LibDeploy._calcContractAddress(
            address(this),
            nonce + 3
        );
        rolesAuthority = new ProfileRoles(address(this), profileAddr);

        // Need beacon proxy to work, must set up fake beacon with fake impl contract
        vm.label(profileAddr, "profile proxy");
        setProfile(profileAddr);
        address impl = address(new SubscribeNFT());
        subscribeBeacon = address(
            new UpgradeableBeacon(impl, address(profile))
        );

        vm.etch(descriptor, address(this).code);

        bytes memory data = abi.encodeWithSelector(
            ProfileNFT.initialize.selector,
            address(0),
            "Name",
            "Symbol",
            descriptor,
            rolesAuthority
        );
        ERC1967Proxy profileProxy = new ERC1967Proxy(
            address(profileImpl),
            data
        );
        assertEq(address(profileProxy), profileAddr);
        profile = MockProfile(address(profileProxy));
    }

    function testAuth() public {
        assertEq(address(profile.authority()), address(rolesAuthority));
    }

    // TODO
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

    function testCannotSetNFTDescriptorAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(alice);
        profile.setNFTDescriptor(descriptor);
    }

    function testCannotSetAnimationTemplateAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(alice);
        profile.setAnimationTemplate("new_ani_template");
    }

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

    // function testWithdraw() public {
    //     rolesAuthority.setUserRole(alice, Constants._PROFILE_GOV_ROLE, true);
    //     vm.deal(address(profile), 2);
    //     assertEq(address(profile).balance, 2);
    //     assertEq(alice.balance, 0);

    //     vm.prank(alice);
    //     vm.expectEmit(true, true, false, true);
    //     emit Withdraw(alice, 1);

    //     profile.withdraw(alice, 1);
    //     assertEq(address(profile).balance, 1);
    //     assertEq(alice.balance, 1);
    // }

    // function testCannotWithdrawInsufficientBal() public {
    //     rolesAuthority.setUserRole(alice, Constants._PROFILE_GOV_ROLE, true);
    //     vm.prank(alice);

    //     vm.expectRevert("INSUFFICIENT_BALANCE");
    //     profile.withdraw(alice, 1);
    // }

    // function testCannotWithdrawAsNonGov() public {
    //     vm.expectRevert("UNAUTHORIZED");
    //     profile.withdraw(alice, 1);
    // }

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

    function testCannotAllowSubscribeMwAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        profile.allowSubscribeMw(address(0), true);
    }

    function testCannotAllowEssenceMwAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        profile.allowEssenceMw(address(0), true);
    }

    function testAllowSubscribeMwAsGov() public {
        address mw = address(0xCA11);
        rolesAuthority.setUserRole(alice, Constants._PROFILE_GOV_ROLE, true);
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit AllowSubscribeMw(mw, false, true);
        profile.allowSubscribeMw(mw, true);

        assertEq(profile.isSubscribeMwAllowed(mw), true);
    }

    function testAllowEssenceMwAsGov() public {
        address mw = address(0xCA11);
        rolesAuthority.setUserRole(alice, Constants._PROFILE_GOV_ROLE, true);
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit AllowEssenceMw(mw, false, true);
        profile.allowEssenceMw(mw, true);

        assertEq(profile.isEssenceMwAllowed(mw), true);
    }

    function testSetLink3ProfileDescriptorGov() public {
        rolesAuthority.setUserRole(alice, Constants._PROFILE_GOV_ROLE, true);

        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit SetNFTDescriptor(descriptor);

        profile.setNFTDescriptor(descriptor);
    }

    function testSetAnimationTemplateGov() public {
        string memory template = "new_ani_template";
        vm.mockCall(
            profile.getNFTDescriptor(),
            abi.encodeWithSelector(
                IProfileNFTDescriptor.setAnimationTemplate.selector,
                template
            ),
            abi.encode(1)
        );
        rolesAuthority.setUserRole(alice, Constants._PROFILE_GOV_ROLE, true);
        vm.expectEmit(true, false, false, true);
        emit SetAnimationTemplate(template);

        vm.prank(alice);
        profile.setAnimationTemplate(template);
    }

    // TODO: etch is not working well with mockCall
    // function testRegisterTwiceWillNotChangePrimaryProfile() public {
    //     // register first time
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

    //     vm.mockCall(
    //         profileAddress,
    //         abi.encodeWithSelector(
    //             IProfileNFT.createProfile.selector,
    //             DataTypes.CreateProfileParams(bob, handle, "", "")
    //         ),
    //         // return false here to indicate that the address has primary profile set already
    //         abi.encode(2, false)
    //     );
    //     vm.mockCall(
    //         profileAddress,
    //         abi.encodeWithSelector(
    //             IProfileNFT.setPrimaryProfile.selector,
    //             bob,
    //             1
    //         ),
    //         abi.encode(0)
    //     );
    //     assertEq(profile.nonces(bob), 0);

    //     vm.expectEmit(true, true, false, true);
    //     emit Register(bob, 1, handle, avatar, metadata);

    //     vm.expectEmit(true, true, false, true);
    //     emit SetPrimaryProfile(bob, 1);

    //     assertEq(
    //         profile.register{ value: Constants._INITIAL_FEE_TIER2 }(
    //             DataTypes.CreateProfileParams(bob, handle, avatar, metadata),
    //             DataTypes.EIP712Signature(v, r, s, deadline)
    //         ),
    //         1
    //     );
    //     assertEq(profile.nonces(bob), 1);
    // }
}
