// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";

import { ProfileDeployer } from "../src/deployer/ProfileDeployer.sol";
import { SubscribeDeployer } from "../src/deployer/SubscribeDeployer.sol";
import { EssenceDeployer } from "../src/deployer/EssenceDeployer.sol";

contract DeployerTest is Test {
    ProfileDeployer pd;
    SubscribeDeployer sd;
    EssenceDeployer ed;
    bytes32 salt = keccak256(bytes("salt"));

    function setUp() public {
        pd = new ProfileDeployer();
        sd = new SubscribeDeployer();
        ed = new EssenceDeployer();
    }

    function testCannotDeploySubcribeWithZeroProfile() public {
        vm.expectRevert("ZERO_ADDRESS");
        sd.deploySubscribe(salt, address(0));
    }

    function testCannotDeployEssenceWithZeroProfile() public {
        vm.expectRevert("ZERO_ADDRESS");
        ed.deployEssence(salt, address(0));
    }

    function testCannotDeployProfileWithZeroEngine() public {
        vm.expectRevert("ENGINE_NOT_SET");
        pd.deployProfile(salt, address(0), address(0xdead), address(0xdead));
    }

    function testCannotDeployProfileWithZeroSubscribe() public {
        vm.expectRevert("SUBSCRIBE_BEACON_NOT_SET");
        pd.deployProfile(salt, address(0xdead), address(0), address(0xdead));
    }

    function testCannotDeployProfileWithZeroEssence() public {
        vm.expectRevert("ESSENCE_BEACON_NOT_SET");
        pd.deployProfile(salt, address(0xdead), address(0xdead), address(0));
    }
}
