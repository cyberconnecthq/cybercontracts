// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import { Constants } from "../src/libraries/Constants.sol";
import { CyberEngine } from "../src/CyberEngine.sol";
import { MockEngineV2 } from "./utils/MockEngineV2.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { RolesAuthority } from "../src/base/RolesAuthority.sol";
import { Authority } from "../src/base/Auth.sol";

contract CyberEngineUpgradeTest is Test {
    RolesAuthority internal rolesAuthority;
    CyberEngine internal impl;
    ERC1967Proxy internal proxy;

    address constant alice = address(0xA11CE);
    address constant bob = address(0xB0B);

    function setUp() public {
        rolesAuthority = new RolesAuthority(
            address(this),
            Authority(address(0))
        );
        impl = new CyberEngine();
        bytes memory functionData = abi.encodeWithSelector(
            CyberEngine.initialize.selector,
            address(0),
            address(this),
            address(this),
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
}
