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

    function setUp() public {
        setParamers(address(0), address(0), address(0), engine);
        MockProfile profileImpl = new MockProfile();
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
        MockProfileV2 implV2 = new MockProfileV2();

        vm.expectRevert("ONLY_ENGINE");
        ProfileNFT(address(profile)).upgradeToAndCall(
            address(implV2),
            abi.encodeWithSelector(MockProfileV2.version.selector)
        );
        assertEq(ProfileNFT(address(profile)).version(), 1);
    }

    function testCannotUpgradeAsNonEngine() public {
        assertEq(ProfileNFT(address(profile)).version(), 1);
        MockProfileV2 implV2 = new MockProfileV2();

        vm.expectRevert("ONLY_ENGINE");
        ProfileNFT(address(profile)).upgradeTo(address(implV2));
        assertEq(ProfileNFT(address(profile)).version(), 1);
    }

    function testUpgrade() public {
        assertEq(ProfileNFT(address(profile)).version(), 1);
        MockProfileV2 implV2 = new MockProfileV2();

        vm.prank(engine);

        ProfileNFT(address(profile)).upgradeTo(address(implV2));
        assertEq(ProfileNFT(address(profile)).version(), 2);
    }

    function testUpgradeToAndCall() public {
        assertEq(ProfileNFT(address(profile)).version(), 1);
        MockProfileV2 implV2 = new MockProfileV2();

        vm.prank(engine);

        ProfileNFT(address(profile)).upgradeToAndCall(
            address(implV2),
            abi.encodeWithSelector(MockProfileV2.version.selector)
        );
        assertEq(ProfileNFT(address(profile)).version(), 2);
    }
}
