// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import { Constants } from "../src/libraries/Constants.sol";
import { CyberEngine } from "../src/CyberEngine.sol";
import { ProfileNFT } from "../src/ProfileNFT.sol";
import { BoxNFT } from "../src/BoxNFT.sol";
import { MockEngineV2 } from "./utils/MockEngineV2.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { RolesAuthority } from "../src/dependencies/solmate/RolesAuthority.sol";
import { Authority } from "../src/dependencies/solmate/Auth.sol";
import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";

contract CyberEngineUpgradeTest is Test {
    RolesAuthority internal rolesAuthority;
    CyberEngine internal impl;
    ERC1967Proxy internal proxy;
    address internal profile = address(0xDEAD);
    address internal box = address(0xDEADB);

    address constant alice = address(0xA11CE);
    address constant bob = address(0xB0B);

    function setUp() public {
        rolesAuthority = new RolesAuthority(
            address(this),
            Authority(address(0))
        );
        impl = new CyberEngine();
        bytes memory code = address(new ProfileNFT(address(0xDEADC0DE))).code;
        vm.etch(profile, code);
        bytes memory boxCode = address(new BoxNFT(address(0xDEADC0DE))).code;
        vm.etch(box, boxCode);
        bytes memory functionData = abi.encodeWithSelector(
            CyberEngine.initialize.selector,
            address(0),
            profile,
            box,
            address(this),
            rolesAuthority
        );
        proxy = new ERC1967Proxy(address(impl), functionData);
        rolesAuthority.setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            address(proxy),
            Constants._AUTHORIZE_UPGRADE,
            true
        );
        rolesAuthority.setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            address(proxy),
            Constants._UPGRADE_PROFILE,
            true
        );

        rolesAuthority.setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            address(proxy),
            Constants._UPGRADE_BOX,
            true
        );
    }

    function testUpgrade() public {
        assertEq(CyberEngine(address(proxy)).version(), 1);
        MockEngineV2 implV2 = new MockEngineV2();

        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.prank(alice);

        CyberEngine(address(proxy)).upgradeTo(address(implV2));
        assertEq(CyberEngine(address(proxy)).version(), 2);
    }

    function testCannotUpgradeAsNonGov() public {
        assertEq(CyberEngine(address(proxy)).version(), 1);
        MockEngineV2 implV2 = new MockEngineV2();

        vm.prank(alice);
        vm.expectRevert("UNAUTHORIZED");
        CyberEngine(address(proxy)).upgradeTo(address(implV2));
        assertEq(CyberEngine(address(proxy)).version(), 1);
    }

    function testCannotUpgradeProfile() public {
        vm.expectRevert("UNAUTHORIZED");

        CyberEngine(address(proxy)).upgradeProfile(address(0xC0DE));
    }

    // TODO: run this in an integration test
    function testUpgradeProfile() public {
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        address v2 = address(0xC0DE);
        vm.mockCall(
            profile,
            abi.encodeWithSelector(UUPSUpgradeable.upgradeTo.selector, v2),
            abi.encode(0)
        );
        vm.prank(alice);
        CyberEngine(address(proxy)).upgradeProfile(v2);
    }

    function testCannotUpgradeBox() public {
        vm.expectRevert("UNAUTHORIZED");
        CyberEngine(address(proxy)).upgradeBox(address(0xC0DE));
    }

    // TODO: run this in an integration test
    function testUpgradeBox() public {
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        address v2 = address(0xC0DE);
        vm.mockCall(
            box,
            abi.encodeWithSelector(UUPSUpgradeable.upgradeTo.selector, v2),
            abi.encode(0)
        );
        vm.prank(alice);
        CyberEngine(address(proxy)).upgradeBox(v2);
    }
}
