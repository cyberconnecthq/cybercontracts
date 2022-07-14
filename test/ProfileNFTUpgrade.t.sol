// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { RolesAuthority } from "../src/dependencies/solmate/RolesAuthority.sol";

import { ProfileNFT } from "../src/core/ProfileNFT.sol";
import { MockProfileV2 } from "./utils/MockProfileV2.sol";
import { MockProfile } from "./utils/MockProfile.sol";
import { TestDeployer } from "./utils/TestDeployer.sol";

contract ProfileNFTUpgradeTest is Test, TestDeployer {
    MockProfile internal profile;
    RolesAuthority internal rolesAuthority;
    ERC1967Proxy internal proxy;
    address constant gov = address(0x888);
    address constant engine = address(0x666);

    function _deployV2(
        address _engine,
        address _essenceBeacon,
        address _subBeacon
    ) internal returns (MockProfileV2 addr) {
        profileParams.engine = _engine;
        profileParams.essenceBeacon = _essenceBeacon;
        profileParams.subBeacon = _subBeacon;
        addr = new MockProfileV2{ salt: _salt }();
        delete profileParams;
    }

    function setUp() public {
        address profileImpl = deployMockProfile(
            engine,
            address(0xdead),
            address(0xdead)
        );
        bytes memory data = abi.encodeWithSelector(
            ProfileNFT.initialize.selector,
            gov,
            "TestProfile",
            "TP",
            address(0)
        );
        ERC1967Proxy profileProxy = new ERC1967Proxy(
            address(profileImpl),
            data
        );
        profile = MockProfile(address(profileProxy));
    }

    function testCannotUpgradeToAndCallAsNonEngine() public {
        assertEq(ProfileNFT(address(profile)).version(), 1);
        MockProfileV2 implV2 = _deployV2(
            engine,
            address(0xdead),
            address(0xdead)
        );

        vm.expectRevert("ONLY_ENGINE");
        ProfileNFT(address(profile)).upgradeToAndCall(
            address(implV2),
            abi.encodeWithSelector(MockProfileV2.version.selector)
        );
        assertEq(ProfileNFT(address(profile)).version(), 1);
    }

    function testCannotUpgradeAsNonEngine() public {
        assertEq(ProfileNFT(address(profile)).version(), 1);
        MockProfileV2 implV2 = _deployV2(
            engine,
            address(0xdead),
            address(0xdead)
        );

        vm.expectRevert("ONLY_ENGINE");
        ProfileNFT(address(profile)).upgradeTo(address(implV2));
        assertEq(ProfileNFT(address(profile)).version(), 1);
    }

    function testUpgrade() public {
        assertEq(ProfileNFT(address(profile)).version(), 1);
        MockProfileV2 implV2 = _deployV2(
            engine,
            address(0xdead),
            address(0xdead)
        );

        vm.prank(engine);

        ProfileNFT(address(profile)).upgradeTo(address(implV2));
        assertEq(ProfileNFT(address(profile)).version(), 2);
    }

    function testUpgradeToAndCall() public {
        assertEq(ProfileNFT(address(profile)).version(), 1);
        MockProfileV2 implV2 = _deployV2(
            engine,
            address(0xdead),
            address(0xdead)
        );

        vm.prank(engine);

        ProfileNFT(address(profile)).upgradeToAndCall(
            address(implV2),
            abi.encodeWithSelector(MockProfileV2.version.selector)
        );
        assertEq(ProfileNFT(address(profile)).version(), 2);
    }
}
