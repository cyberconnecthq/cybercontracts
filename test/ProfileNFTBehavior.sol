// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import { MockProfile } from "./utils/MockProfile.sol";
import { Constants } from "../src/libraries/Constants.sol";
import { IProfileNFT } from "../src/interfaces/IProfileNFT.sol";
import { RolesAuthority } from "../src/dependencies/solmate/RolesAuthority.sol";
import { Roles } from "../src/core/Roles.sol";
import { ProfileNFT } from "../src/core/ProfileNFT.sol";
import { SubscribeNFT } from "../src/core/SubscribeNFT.sol";
import { UpgradeableBeacon } from "../src/upgradeability/UpgradeableBeacon.sol";
import { Authority } from "../src/dependencies/solmate/Auth.sol";
import { DataTypes } from "../src/libraries/DataTypes.sol";
import { ECDSA } from "../src/dependencies/openzeppelin/ECDSA.sol";
import { IProfileNFTEvents } from "../src/interfaces/IProfileNFTEvents.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { LibDeploy } from "../script/libraries/LibDeploy.sol";
import { IProfileNFTDescriptor } from "../src/interfaces/IProfileNFTDescriptor.sol";
import { ProfileNFTDescriptor } from "../src/periphery/ProfileNFTDescriptor.sol";

contract ProfileNFTBehaviorTest is Test, IProfileNFTEvents {
    MockProfile internal engine;
    RolesAuthority internal rolesAuthority;
    address internal essenceBeacon = address(0xC);
    address internal profileNFTDescriptor = address(0xD);
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
        MockProfile engineImpl = new MockProfile(address(0), address(0));
        uint256 nonce = vm.getNonce(address(this));
        address engineAddr = LibDeploy._calcContractAddress(
            address(this),
            nonce + 3
        );
        rolesAuthority = new Roles(address(this), engineAddr);

        // Need beacon proxy to work, must set up fake beacon with fake impl contract
        vm.label(engineAddr, "eng proxy");
        address impl = address(new SubscribeNFT(engineAddr));
        subscribeBeacon = address(new UpgradeableBeacon(impl, address(engine)));

        vm.etch(descriptor, address(this).code);

        bytes memory data = abi.encodeWithSelector(
            ProfileNFT.initialize.selector,
            address(0),
            "Name",
            "Symbol",
            descriptor,
            rolesAuthority
        );
        ERC1967Proxy engineProxy = new ERC1967Proxy(address(engineImpl), data);
        assertEq(address(engineProxy), engineAddr);
        engine = MockProfile(address(engineProxy));
    }

    function testAuth() public {
        assertEq(address(engine.authority()), address(rolesAuthority));
    }

    function testCannotSetSignerAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(alice);
        engine.setSigner(alice);
    }

    function testCannotSetFeeAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(alice);
        engine.setFeeByTier(DataTypes.Tier.Tier0, 1);
    }

    function testCannotSetProfileNFTDescriptorAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(alice);
        engine.setProfileNFTDescriptor(profileNFTDescriptor);
    }

    function testCannotSetAnimationTemplateAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(alice);
        engine.setAnimationTemplate("new_ani_template");
    }

    function testSetSignerAsGov() public {
        rolesAuthority.setUserRole(alice, Constants._PROFILE_GOV_ROLE, true);
        vm.prank(alice);

        vm.expectEmit(true, true, false, true);
        emit SetSigner(address(0), alice);

        engine.setSigner(alice);
    }

    function testSetFeeGov() public {
        rolesAuthority.setUserRole(alice, Constants._PROFILE_GOV_ROLE, true);
        vm.prank(alice);

        vm.expectEmit(true, true, true, true);
        emit SetFeeByTier(
            DataTypes.Tier.Tier0,
            Constants._INITIAL_FEE_TIER0,
            1
        );

        engine.setFeeByTier(DataTypes.Tier.Tier0, 1);
        assertEq(engine.feeMapping(DataTypes.Tier.Tier0), 1);
    }

    function testVerify() public {
        // set charlie as signer
        address charlie = vm.addr(1);
        rolesAuthority.setUserRole(alice, Constants._PROFILE_GOV_ROLE, true);
        vm.prank(alice);
        engine.setSigner(charlie);

        // change block timestamp to make deadline valid
        vm.warp(50);
        uint256 deadline = 100;
        bytes32 digest = engine.hashTypedDataV4(
            keccak256(
                abi.encode(
                    Constants._REGISTER_TYPEHASH,
                    bob,
                    keccak256(bytes(handle)),
                    keccak256(bytes(avatar)),
                    keccak256(bytes(metadata)),
                    0,
                    deadline
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);
        engine.verifySignature(
            digest,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
    }

    function testCannotVerifyAsNonSigner() public {
        // change block timestamp to make deadline valid
        vm.warp(50);
        uint256 deadline = 100;
        bytes32 digest = engine.hashTypedDataV4(
            keccak256(
                abi.encode(
                    Constants._REGISTER_TYPEHASH,
                    bob,
                    keccak256(bytes(handle)),
                    keccak256(bytes(avatar)),
                    keccak256(bytes(metadata)),
                    0,
                    deadline
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);

        vm.expectRevert("INVALID_SIGNATURE");
        engine.verifySignature(
            digest,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
    }

    function testCannotVerifyDeadlinePassed() public {
        // change block timestamp to make deadline invalid
        vm.warp(150);
        uint256 deadline = 100;
        bytes32 digest = engine.hashTypedDataV4(
            keccak256(
                abi.encode(
                    Constants._REGISTER_TYPEHASH,
                    bob,
                    keccak256(bytes(handle)),
                    keccak256(bytes(avatar)),
                    keccak256(bytes(metadata)),
                    0,
                    deadline
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);

        vm.expectRevert("DEADLINE_EXCEEDED");
        engine.verifySignature(
            digest,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
    }

    function testInitialFees() public {
        assertEq(
            engine.feeMapping(DataTypes.Tier.Tier0),
            Constants._INITIAL_FEE_TIER0
        );
        assertEq(
            engine.feeMapping(DataTypes.Tier.Tier1),
            Constants._INITIAL_FEE_TIER1
        );
        assertEq(
            engine.feeMapping(DataTypes.Tier.Tier2),
            Constants._INITIAL_FEE_TIER2
        );
        assertEq(
            engine.feeMapping(DataTypes.Tier.Tier3),
            Constants._INITIAL_FEE_TIER3
        );
        assertEq(
            engine.feeMapping(DataTypes.Tier.Tier4),
            Constants._INITIAL_FEE_TIER4
        );
        assertEq(
            engine.feeMapping(DataTypes.Tier.Tier5),
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
        rolesAuthority.setUserRole(alice, Constants._PROFILE_GOV_ROLE, true);
        vm.deal(address(engine), 2);
        assertEq(address(engine).balance, 2);
        assertEq(alice.balance, 0);

        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit Withdraw(alice, 1);

        engine.withdraw(alice, 1);
        assertEq(address(engine).balance, 1);
        assertEq(alice.balance, 1);
    }

    function testCannotWithdrawInsufficientBal() public {
        rolesAuthority.setUserRole(alice, Constants._PROFILE_GOV_ROLE, true);
        vm.prank(alice);

        vm.expectRevert("Insufficient balance");
        engine.withdraw(alice, 1);
    }

    function testCannotWithdrawAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        engine.withdraw(alice, 1);
    }

    function testRegister() public {
        address charlie = vm.addr(1);
        rolesAuthority.setUserRole(alice, Constants._PROFILE_GOV_ROLE, true);
        vm.prank(alice);
        engine.setSigner(charlie);

        // change block timestamp to make deadline valid
        vm.warp(50);
        uint256 deadline = 100;
        bytes32 digest = engine.hashTypedDataV4(
            keccak256(
                abi.encode(
                    Constants._REGISTER_TYPEHASH,
                    bob,
                    keccak256(bytes(handle)),
                    keccak256(bytes(avatar)),
                    keccak256(bytes(metadata)),
                    0,
                    deadline
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);

        assertEq(engine.nonces(bob), 0);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), bob, 1);

        vm.expectEmit(true, true, false, true);
        emit SetPrimaryProfile(bob, 1);

        vm.expectEmit(true, true, false, true);
        emit Register(bob, 1, handle, avatar, metadata);

        assertEq(
            engine.createProfile{ value: Constants._INITIAL_FEE_TIER2 }(
                DataTypes.CreateProfileParams(bob, handle, avatar, metadata),
                DataTypes.EIP712Signature(v, r, s, deadline)
            ),
            1
        );
        assertEq(engine.nonces(bob), 1);
    }

    function testCannotRegisterInvalidSig() public {
        // set charlie as signer
        address charlie = vm.addr(1);
        rolesAuthority.setUserRole(alice, Constants._PROFILE_GOV_ROLE, true);
        vm.prank(alice);
        engine.setSigner(charlie);

        // change block timestamp to make deadline valid
        vm.warp(50);
        uint256 deadline = 100;
        bytes32 digest = engine.hashTypedDataV4(
            keccak256(
                abi.encode(
                    Constants._REGISTER_TYPEHASH,
                    bob,
                    keccak256(bytes(handle)),
                    keccak256(bytes(avatar)),
                    keccak256(bytes(metadata)),
                    0,
                    deadline
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);

        // charlie signed the handle to bob, but register with a different address(alice).
        vm.expectRevert("INVALID_SIGNATURE");
        engine.createProfile{ value: Constants._INITIAL_FEE_TIER2 }(
            DataTypes.CreateProfileParams(alice, handle, avatar, metadata),
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
    }

    function testCannotRegisterReplay() public {
        // set charlie as signer
        address charlie = vm.addr(1);
        rolesAuthority.setUserRole(alice, Constants._PROFILE_GOV_ROLE, true);
        vm.prank(alice);
        engine.setSigner(charlie);

        // change block timestamp to make deadline valid
        vm.warp(50);
        uint256 deadline = 100;
        bytes32 digest = engine.hashTypedDataV4(
            keccak256(
                abi.encode(
                    Constants._REGISTER_TYPEHASH,
                    bob,
                    keccak256(bytes(handle)),
                    keccak256(bytes(avatar)),
                    keccak256(bytes(metadata)),
                    0,
                    deadline
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);
        engine.createProfile{ value: Constants._INITIAL_FEE_TIER2 }(
            DataTypes.CreateProfileParams(bob, handle, avatar, metadata),
            DataTypes.EIP712Signature(v, r, s, deadline)
        );

        vm.expectRevert("INVALID_SIGNATURE");
        engine.createProfile{ value: Constants._INITIAL_FEE_TIER2 }(
            DataTypes.CreateProfileParams(bob, handle, avatar, metadata),
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
    }

    function testCannotAllowSubscribeMwAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        engine.allowSubscribeMw(address(0), true);
    }

    function testCannotAllowEssenceMwAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        engine.allowEssenceMw(address(0), true);
    }

    function testAllowSubscribeMwAsGov() public {
        address mw = address(0xCA11);
        rolesAuthority.setUserRole(alice, Constants._PROFILE_GOV_ROLE, true);
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit AllowSubscribeMw(mw, false, true);
        engine.allowSubscribeMw(mw, true);

        assertEq(engine.isSubscribeMwAllowed(mw), true);
    }

    function testAllowEssenceMwAsGov() public {
        address mw = address(0xCA11);
        rolesAuthority.setUserRole(alice, Constants._PROFILE_GOV_ROLE, true);
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit AllowEssenceMw(mw, false, true);
        engine.allowEssenceMw(mw, true);

        assertEq(engine.isEssenceMwAllowed(mw), true);
    }

    function testSetProfileNFTDescriptorGov() public {
        rolesAuthority.setUserRole(alice, Constants._PROFILE_GOV_ROLE, true);

        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit SetProfileNFTDescriptor(profileNFTDescriptor);

        engine.setProfileNFTDescriptor(profileNFTDescriptor);
    }

    function testSetAnimationTemplateGov() public {
        string memory template = "new_ani_template";
        vm.mockCall(
            engine.getProfileNFTDescriptor(),
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
        engine.setAnimationTemplate(template);
    }

    // TODO: etch is not working well with mockCall
    // function testRegisterTwiceWillNotChangePrimaryProfile() public {
    //     // register first time
    //     address charlie = vm.addr(1);
    //     rolesAuthority.setUserRole(alice, Constants._PROFILE_GOV_ROLE, true);
    //     vm.prank(alice);
    //     engine.setSigner(charlie);

    //     // change block timestamp to make deadline valid
    //     vm.warp(50);
    //     uint256 deadline = 100;
    //     bytes32 digest = engine.hashTypedDataV4(
    //         keccak256(
    //             abi.encode(
    //                 Constants._REGISTER_TYPEHASH,
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
    //     assertEq(engine.nonces(bob), 0);

    //     vm.expectEmit(true, true, false, true);
    //     emit Register(bob, 1, handle, avatar, metadata);

    //     vm.expectEmit(true, true, false, true);
    //     emit SetPrimaryProfile(bob, 1);

    //     assertEq(
    //         engine.register{ value: Constants._INITIAL_FEE_TIER2 }(
    //             DataTypes.CreateProfileParams(bob, handle, avatar, metadata),
    //             DataTypes.EIP712Signature(v, r, s, deadline)
    //         ),
    //         1
    //     );
    //     assertEq(engine.nonces(bob), 1);
    // }
}
