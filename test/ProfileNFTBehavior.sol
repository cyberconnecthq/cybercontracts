// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { IProfileNFT } from "../src/interfaces/IProfileNFT.sol";
import { IProfileNFTEvents } from "../src/interfaces/IProfileNFTEvents.sol";
import { IProfileNFTDescriptor } from "../src/interfaces/IProfileNFTDescriptor.sol";

import { Constants } from "../src/libraries/Constants.sol";
import { DataTypes } from "../src/libraries/DataTypes.sol";

import { MockProfile } from "./utils/MockProfile.sol";
import { ProfileNFT } from "../src/core/ProfileNFT.sol";
import { SubscribeNFT } from "../src/core/SubscribeNFT.sol";
import { UpgradeableBeacon } from "../src/upgradeability/UpgradeableBeacon.sol";
import { Link3ProfileDescriptor } from "../src/periphery/Link3ProfileDescriptor.sol";
import { TestDeployer } from "./utils/TestDeployer.sol";

contract ProfileNFTBehaviorTest is Test, IProfileNFTEvents, TestDeployer {
    MockProfile internal profile;
    address internal essenceBeacon = address(0xC);
    address internal subscribeBeacon;
    address constant alice = address(0xA11CE);
    address constant bob = address(0xB0B);
    address constant gov = address(0x8888);
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
        vm.etch(descriptor, address(this).code);

        MockProfile profileImpl = new MockProfile();
        uint256 nonce = vm.getNonce(address(this));
        // Need beacon proxy to work, must set up fake beacon with fake impl contract
        setProfile(address(0xdead));
        address impl = address(new SubscribeNFT());
        subscribeBeacon = address(
            new UpgradeableBeacon(impl, address(profile))
        );

        bytes memory data = abi.encodeWithSelector(
            ProfileNFT.initialize.selector,
            gov,
            "Name",
            "Symbol"
        );
        ERC1967Proxy profileProxy = new ERC1967Proxy(
            address(profileImpl),
            data
        );
        profile = MockProfile(address(profileProxy));
    }

    function testCannotSetNFTDescriptorAsNonGov() public {
        vm.expectRevert("ONLY_NAMESPACE_OWNER");
        vm.prank(alice);
        profile.setNFTDescriptor(descriptor);
    }

    function testCannotSetAnimationTemplateAsNonGov() public {
        vm.expectRevert("ONLY_NAMESPACE_OWNER");
        vm.prank(alice);
        profile.setAnimationTemplate("new_ani_template");
    }

    function testSetDescriptorGov() public {
        vm.prank(gov);
        vm.expectEmit(true, false, false, true);
        emit SetNFTDescriptor(descriptor);

        profile.setNFTDescriptor(descriptor);
    }

    function testSetAnimationTemplateGov() public {
        vm.startPrank(gov);
        profile.setNFTDescriptor(descriptor);

        string memory template = "new_ani_template";
        vm.mockCall(
            profile.getNFTDescriptor(),
            abi.encodeWithSelector(
                IProfileNFTDescriptor.setAnimationTemplate.selector,
                template
            ),
            abi.encode(1)
        );
        vm.expectEmit(true, false, false, true);
        emit SetAnimationTemplate(template);

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
