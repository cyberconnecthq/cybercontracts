pragma solidity 0.8.14;

import "../src/CyberEngine.sol";
import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/libraries/Constants.sol";
import "solmate/auth/authorities/RolesAuthority.sol";
import {Authority} from "solmate/auth/Auth.sol";

contract CyberEngineTest is Test {
    CyberEngine internal engine;
    RolesAuthority internal rolesAuthority;
    address constant alice = address(0xA11CE);
    address constant profileAddr = address(0xB11CE);
    address constant boxAddr = address(0xC11CE);

    function setUp() public {
        rolesAuthority = new RolesAuthority(address(this), Authority(address(0)));
        engine = new CyberEngine(address(this), profileAddr, boxAddr, rolesAuthority);
        rolesAuthority.setRoleCapability(
            Constants.ENGINE_GOV_ROLE,
            address(engine),
            Constants.SET_SIGNER,
            true
        );
        rolesAuthority.setRoleCapability(
            Constants.ENGINE_GOV_ROLE,
            address(engine),
            Constants.SET_PROFILE_ADDR,
            true
        );
        rolesAuthority.setRoleCapability(
            Constants.ENGINE_GOV_ROLE,
            address(engine),
            Constants.SET_BOX_ADDR,
            true
        );
    }

    function testBasic() public {
        assertEq(engine.profileAddress(), profileAddr);
        assertEq(engine.boxAddress(), boxAddr);
    }

    function testAuth() public {
        assertEq(address(engine.authority()), address(rolesAuthority));
    }

    function testCannotSetSignerAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(address(0));
        engine.setSigner(alice);
    }

    function testCannotSetProfileAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(address(0));
        engine.setProfileAddress(alice);
    }

    function testCannotSetBoxAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(address(0));
        engine.setBoxAddress(alice);
    }

    function testSetSignerAsGov() public {
        rolesAuthority.setUserRole(alice, Constants.ENGINE_GOV_ROLE, true);
        vm.prank(alice);
        engine.setSigner(alice);
    }

    function testSetProfileAsGov() public {
        rolesAuthority.setUserRole(alice, Constants.ENGINE_GOV_ROLE, true);
        vm.prank(alice);
        engine.setProfileAddress(alice);
    }

    function testSetBoxGov() public {
        rolesAuthority.setUserRole(alice, Constants.ENGINE_GOV_ROLE, true);
        vm.prank(alice);
        engine.setBoxAddress(alice);
    }
}
