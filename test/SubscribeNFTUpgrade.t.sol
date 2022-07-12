// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;
import "forge-std/Test.sol";
import { IProfileNFT } from "../src/interfaces/IProfileNFT.sol";
import { UpgradeableBeacon } from "../src/upgradeability/UpgradeableBeacon.sol";
import { SubscribeNFT } from "../src/core/SubscribeNFT.sol";
import { BeaconProxy } from "openzeppelin-contracts/contracts/proxy/beacon/BeaconProxy.sol";
import { LibString } from "../src/libraries/LibString.sol";
import { Constants } from "../src/libraries/Constants.sol";
import { MockSubscribeNFTV2 } from "./utils/MockSubscribeNFTV2.sol";
import { MockProfile } from "./utils/MockProfile.sol";
import { TestDeployer } from "./utils/TestDeployer.sol";

contract SubscribeNFTUpgradeTest is Test, TestDeployer {
    UpgradeableBeacon internal beacon;
    SubscribeNFT internal impl;
    BeaconProxy internal proxy;
    BeaconProxy internal proxyB;
    MockProfile internal profile;

    uint256 internal profileId = 1;
    address constant alice = address(0xA11CE);

    function setUp() public {
        profile = new MockProfile();
        setProfile(address(profile));
        impl = new SubscribeNFT();
        beacon = new UpgradeableBeacon(address(impl), address(profile));
        bytes memory functionData = abi.encodeWithSelector(
            SubscribeNFT.initialize.selector,
            profileId,
            "name",
            "SYMBOL"
        );
        proxy = new BeaconProxy(address(beacon), functionData);
        proxyB = new BeaconProxy(address(beacon), functionData);
    }

    function testAuth() public {
        assertEq(beacon.OWNER(), address(profile));
    }

    function testUpgrade() public {
        MockSubscribeNFTV2 implB = new MockSubscribeNFTV2();

        assertEq(SubscribeNFT(address(proxy)).version(), 1);
        assertEq(SubscribeNFT(address(proxyB)).version(), 1);

        vm.prank(address(profile));
        beacon.upgradeTo(address(implB));

        MockSubscribeNFTV2 p = MockSubscribeNFTV2(address(proxy));
        MockSubscribeNFTV2 pB = MockSubscribeNFTV2(address(proxyB));

        assertEq(p.version(), 2);
        assertEq(pB.version(), 2);
    }
}
