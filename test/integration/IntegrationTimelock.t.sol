// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { TimelockController } from "openzeppelin-contracts/contracts/governance/TimelockController.sol";

import { IProfileNFTEvents } from "../../src/interfaces/IProfileNFTEvents.sol";

import { LibDeploy } from "../../script/libraries/LibDeploy.sol";

import { RolesAuthority } from "../../src/dependencies/solmate/RolesAuthority.sol";
import { Link3ProfileDescriptor } from "../../src/periphery/Link3ProfileDescriptor.sol";
import { ProfileNFT } from "../../src/core/ProfileNFT.sol";
import { Treasury } from "../../src/middlewares/base/Treasury.sol";
import { TestIntegrationBase } from "../utils/TestIntegrationBase.sol";
import { CyberBoxNFT } from "../../src/periphery/CyberBoxNFT.sol";

import "forge-std/console.sol";

contract IntegrationTimelockTest is TestIntegrationBase, IProfileNFTEvents {
    address tlOwner = address(0x1);
    address newOwner = address(0x2);

    function setUp() public {
        _setUp();
    }

    function testTimelock() public {
        uint256 delay = 48 * 3600;
        address timelock = LibDeploy.deployTimeLock(vm, tlOwner, delay, false);

        require(
            RolesAuthority(addrs.engineAuthority).owner() == address(this),
            "WRONG_ENGINE_AUTH_OWNER"
        );
        require(
            Link3ProfileDescriptor(addrs.link3DescriptorProxy).owner() ==
                address(this),
            "WRONG_DESC_OWNER"
        );
        require(
            Treasury(addrs.cyberTreasury).owner() == address(this),
            "WRONG_TREASURY_OWNER"
        );
        require(
            Treasury(addrs.cyberBox).owner() == address(this),
            "WRONG_BOX_OWNER"
        );

        LibDeploy.changeOwnership(
            vm,
            timelock,
            address(this),
            addrs.engineAuthority, // role auth
            addrs.cyberBox, // box proxy
            addrs.link3DescriptorProxy, // desc proxy
            addrs.cyberTreasury // treasury proxy
        );

        require(
            RolesAuthority(addrs.engineAuthority).owner() == timelock,
            "WRONG_ENGINE_AUTH_OWNER"
        );
        require(
            Link3ProfileDescriptor(addrs.link3DescriptorProxy).owner() ==
                timelock,
            "WRONG_DESC_OWNER"
        );
        require(
            Treasury(addrs.cyberTreasury).owner() == timelock,
            "WRONG_TREASURY_OWNER"
        );
        require(
            Treasury(addrs.cyberBox).owner() == timelock,
            "WRONG_BOX_OWNER"
        );

        vm.startPrank(tlOwner);

        bytes memory data = abi.encodeWithSignature(
            "setOwner(address)",
            newOwner
        );
        TimelockController(payable(timelock)).schedule(
            addrs.engineAuthority,
            0,
            data,
            0,
            0,
            delay
        );
        TimelockController(payable(timelock)).schedule(
            addrs.link3DescriptorProxy,
            0,
            data,
            0,
            0,
            delay
        );
        TimelockController(payable(timelock)).schedule(
            addrs.cyberTreasury,
            0,
            data,
            0,
            0,
            delay
        );
        TimelockController(payable(timelock)).schedule(
            addrs.cyberBox,
            0,
            data,
            0,
            0,
            delay
        );

        vm.warp(delay + 1);

        TimelockController(payable(timelock)).execute(
            addrs.engineAuthority,
            0,
            data,
            0,
            0
        );
        TimelockController(payable(timelock)).execute(
            addrs.link3DescriptorProxy,
            0,
            data,
            0,
            0
        );
        TimelockController(payable(timelock)).execute(
            addrs.cyberTreasury,
            0,
            data,
            0,
            0
        );
        TimelockController(payable(timelock)).execute(
            addrs.cyberBox,
            0,
            data,
            0,
            0
        );

        vm.stopPrank();

        require(
            RolesAuthority(addrs.engineAuthority).owner() == newOwner,
            "WRONG_ENGINE_AUTH_OWNER"
        );
        require(
            Link3ProfileDescriptor(addrs.link3DescriptorProxy).owner() ==
                newOwner,
            "WRONG_DESC_OWNER"
        );
        require(
            Treasury(addrs.cyberTreasury).owner() == newOwner,
            "WRONG_TREASURY_OWNER"
        );
        require(
            Treasury(addrs.cyberBox).owner() == newOwner,
            "WRONG_BOX_OWNER"
        );
    }
}
