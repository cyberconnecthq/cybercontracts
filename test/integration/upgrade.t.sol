// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "../../src/upgradeability/UpgradeableBeacon.sol";
import "openzeppelin-contracts/contracts/mocks/RegressionImplementation.sol";
import "forge-std/Test.sol";
import { IUpgradeableBeaconEvents } from "../../src/interfaces/IUpgradeableBeaconEvents.sol";

contract UpgradeableBeaconTest is Test, IUpgradeableBeaconEvents {
    address internal owner = address(0xA11CE);
    address internal other = address(0xB0B);
    Implementation1 v1;
    UpgradeableBeacon beacon;
    function setUp() public {
        v1 = new Implementation1();
        beacon = new UpgradeableBeacon(address(v1), owner);
    }

    function testCannotCreatedWithNonContractImplementation() public {
        vm.expectRevert(bytes("UpgradeableBeacon: implementation is not a contract"));
        UpgradeableBeacon temp = new UpgradeableBeacon(owner, address(0));
    }

    function testReturnsImplementation() public {
        assertEq(beacon.implementation(), address(v1));
    }

    function testCanBeUpgradedByTheOwner() public {
        Implementation2 v2 = new Implementation2();
        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit Upgraded(address(v2));
        beacon.upgradeTo(address(v2));
        assertEq(beacon.implementation(), address(v2));
    }

    function testCannotUpgradeByNonContract() public {
        vm.expectRevert(bytes("Only Engine"));
        beacon.upgradeTo(other);
    }

    function testCannotUpgradeByOtherAccount() public {
        Implementation2 v2 = new Implementation2();
        vm.expectRevert(bytes("Only Engine"));
        beacon.upgradeTo(address(v2));
    }
}
