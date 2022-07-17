// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { RolesAuthority } from "../src/dependencies/solmate/RolesAuthority.sol";
import { Authority } from "../src/dependencies/solmate/Auth.sol";

import { Constants } from "../src/libraries/Constants.sol";

import { CyberEngine } from "../src/core/CyberEngine.sol";
import { MockEngineV2 } from "./utils/MockEngineV2.sol";

contract CyberEngineUpgradeTest is Test {
    RolesAuthority internal rolesAuthority;
    CyberEngine internal engine;
    ERC1967Proxy internal proxy;
    address internal profile = address(0xDEAD);

    address constant alice = address(0xA11CE);
    address constant bob = address(0xB0B);

    function setUp() public {
        CyberEngine engineImpl = new CyberEngine();
        rolesAuthority = new RolesAuthority(
            address(this),
            Authority(address(0))
        );
        bytes memory data = abi.encodeWithSelector(
            CyberEngine.initialize.selector,
            address(0),
            rolesAuthority
        );
        ERC1967Proxy engineProxy = new ERC1967Proxy(address(engineImpl), data);
        engine = CyberEngine(address(engineProxy));

        RolesAuthority(rolesAuthority).setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            address(engine),
            CyberEngine.allowProfileMw.selector,
            true
        );
        RolesAuthority(rolesAuthority).setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            address(engine),
            Constants._AUTHORIZE_UPGRADE,
            true
        );
    }

    function testCannotUpgradeToAndCallAsNonGov() public {
        assertEq(CyberEngine(address(engine)).version(), 1);
        MockEngineV2 implV2 = new MockEngineV2();

        vm.prank(alice);
        vm.expectRevert("UNAUTHORIZED");
        CyberEngine(address(engine)).upgradeToAndCall(
            address(implV2),
            abi.encodeWithSelector(MockEngineV2.version.selector)
        );
        assertEq(CyberEngine(address(engine)).version(), 1);
    }

    function testCannotUpgradeAsNonGov() public {
        assertEq(CyberEngine(address(engine)).version(), 1);
        MockEngineV2 implV2 = new MockEngineV2();

        vm.prank(alice);
        vm.expectRevert("UNAUTHORIZED");
        CyberEngine(address(engine)).upgradeTo(address(implV2));
        assertEq(CyberEngine(address(engine)).version(), 1);
    }

    function testUpgrade() public {
        assertEq(CyberEngine(address(engine)).version(), 1);
        MockEngineV2 implV2 = new MockEngineV2();

        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.prank(alice);

        CyberEngine(address(engine)).upgradeTo(address(implV2));
        assertEq(CyberEngine(address(engine)).version(), 2);
    }

    function testUpgradeToAndCall() public {
        assertEq(CyberEngine(address(engine)).version(), 1);
        MockEngineV2 implV2 = new MockEngineV2();

        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.prank(alice);

        CyberEngine(address(engine)).upgradeToAndCall(
            address(implV2),
            abi.encodeWithSelector(MockEngineV2.version.selector)
        );
        assertEq(CyberEngine(address(engine)).version(), 2);
    }
}
