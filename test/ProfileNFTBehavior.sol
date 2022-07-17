// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { IProfileNFTEvents } from "../src/interfaces/IProfileNFTEvents.sol";

import { DataTypes } from "../src/libraries/DataTypes.sol";

import { MockProfile } from "./utils/MockProfile.sol";
import { ProfileNFT } from "../src/core/ProfileNFT.sol";
import { UpgradeableBeacon } from "../src/upgradeability/UpgradeableBeacon.sol";
import { TestDeployer } from "./utils/TestDeployer.sol";

contract ProfileNFTBehaviorTest is Test, IProfileNFTEvents, TestDeployer {
    MockProfile internal profile;
    address internal essenceBeacon = address(0xC);
    address internal subscribeBeacon;
    address constant alice = address(0xA11CE);
    address constant gov = address(0x8888);
    address descriptor = address(0x233);
    DataTypes.CreateProfileParams internal createProfileDataAlice =
        DataTypes.CreateProfileParams(
            alice,
            "alice",
            "https://example.com/alice.jpg",
            "metadata"
        );

    function setUp() public {
        vm.etch(descriptor, address(this).code);

        // Need beacon proxy to work, must set up fake beacon with fake impl contract
        address impl = address(
            deploySubscribe(keccak256(bytes("salt")), address(0xdead))
        );
        subscribeBeacon = address(
            new UpgradeableBeacon(impl, address(profile))
        );

        address profileImpl = deployMockProfile(
            address(0xdead),
            essenceBeacon,
            subscribeBeacon
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

    function testSetDescriptorGov() public {
        vm.prank(gov);
        vm.expectEmit(true, false, false, true);
        emit SetNFTDescriptor(descriptor);

        profile.setNFTDescriptor(descriptor);
    }

    function testRegisterTwiceWillNotChangePrimaryProfile() public {
        profile.createProfile(createProfileDataAlice);
        assertEq(profile.getHandleByProfileId(1), "alice");
        assertEq(profile.getPrimaryProfile(alice), 1);

        createProfileDataAlice.handle = "alice2";
        profile.createProfile(createProfileDataAlice);
        assertEq(profile.getHandleByProfileId(2), "alice2");
        assertEq(profile.getPrimaryProfile(alice), 1);
    }
}
