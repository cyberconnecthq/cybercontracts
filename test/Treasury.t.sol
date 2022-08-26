// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";

import { Constants } from "../src/libraries/Constants.sol";

import { Treasury } from "../src/middlewares/base/Treasury.sol";

contract TreasuryTest is Test {
    Treasury t;
    address constant owner = address(0xA11CE);
    address constant bob = address(0xB0B);
    address constant token = address(0x111);

    function setUp() public {
        t = new Treasury(owner, bob, 200);
    }

    function testBasic() public {
        assertEq(t.getTreasuryAddress(), bob);
        assertEq(t.getTreasuryFee(), 200);
    }

    function testSetTreasuryFee() public {
        vm.prank(owner);
        t.setTreasuryFee(300);
        assertEq(t.getTreasuryFee(), 300);
    }

    function testCannotSetTreasuryFeeExceedMax() public {
        vm.prank(owner);
        vm.expectRevert("INVALID_TREASURY_FEE");
        t.setTreasuryFee(Constants._MAX_BPS + 1);
    }

    function testCannotSetTreasuryFeeNonOwner() public {
        vm.expectRevert("UNAUTHORIZED");
        t.setTreasuryFee(Constants._MAX_BPS);
    }

    function testSetTreasuryAddress() public {
        vm.prank(owner);
        t.setTreasuryAddress(bob);
        assertEq(t.getTreasuryAddress(), bob);
    }

    function testCannotSetTreasuryAddressNonOwner() public {
        vm.expectRevert("UNAUTHORIZED");
        t.setTreasuryAddress(bob);
    }

    function testAllowCurrency() public {
        vm.startPrank(owner);
        assertEq(t.isCurrencyAllowed(token), false);
        t.allowCurrency(token, true);
        assertEq(t.isCurrencyAllowed(token), true);
    }

    function testCannotAllowCurrencyNonOwner() public {
        vm.expectRevert("UNAUTHORIZED");
        t.allowCurrency(token, true);
    }
}
