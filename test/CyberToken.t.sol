// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";
import { ERC20 } from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { CYBER } from "../src/cybertoken/CYBER.sol";
import { TestIntegrationBase } from "../test/utils/TestIntegrationBase.sol";

contract CyberTokenTest is TestIntegrationBase {
    uint256 amountRequired;
    bool subscribeRequired;
    address lila = address(0x1114);
    address bobby = address(0xB0B);
    address dave = address(0xD02);
    uint256 maxTransferAmount = 200;
    CYBER cyberTokenContract;

    function setUp() public {
        _setUp();

        vm.label(address(lila), "lila");
        vm.label(address(bobby), "bobby");
        vm.label(address(dave), "dave");

        // initialize the cyber contract, bobby is the owner, this contract is where all the initial fund is initially sent to.
        cyberTokenContract = new CYBER(bobby, address(this));
        vm.label(address(cyberTokenContract), "Cyber Token Contract");

        // this is the starting balance and also the total supply of the cyber token contract
        uint256 startingBalance = IERC20(address(cyberTokenContract)).balanceOf(
            address(this)
        );

        // then from this contract, we airdrop 200 tokens to lila
        cyberTokenContract.transfer(lila, 200);

        assertEq(
            IERC20(address(cyberTokenContract)).balanceOf(address(this)),
            startingBalance - 200
        );
        assertEq(IERC20(address(cyberTokenContract)).balanceOf(lila), 200);
    }

    function testTransferToken() public {
        // when did the total supply get put into the ERC20??????
        console.log("total", IERC20(address(cyberTokenContract)).totalSupply());

        vm.prank(lila);
        cyberTokenContract.transfer(address(dave), 50);

        assertEq(IERC20(address(cyberTokenContract)).balanceOf(dave), 50);
        assertEq(IERC20(address(cyberTokenContract)).balanceOf(lila), 150);
    }

    function testTakeTokenWithApproval() public {
        vm.prank(lila);
        cyberTokenContract.approve(address(dave), 100);

        vm.prank(dave);
        cyberTokenContract.transferFrom(lila, dave, 50);
        assertEq(IERC20(address(cyberTokenContract)).balanceOf(dave), 50);
        assertEq(IERC20(address(cyberTokenContract)).balanceOf(lila), 150);
    }

    function testTransferOwnership() public {
        assertEq(cyberTokenContract.owner(), bobby);

        vm.prank(bobby);
        cyberTokenContract.transferOwnership(lila);
        assertEq(cyberTokenContract.owner(), lila);

        vm.prank(dave);
        vm.expectRevert("Ownable: caller is not the owner");
        cyberTokenContract.transferOwnership(lila);
    }
}
