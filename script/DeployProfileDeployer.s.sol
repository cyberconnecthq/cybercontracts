// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";
import { Create2Deployer } from "../src/deployer/Create2Deployer.sol";
import { ProfileDeployer } from "../src/deployer/ProfileDeployer.sol";

contract DeployScript is Script, DeploySetting {
    bytes32 constant SALT = keccak256(bytes("CyberConnect"));

    function run() external {
        _setDeployParams();
        vm.startBroadcast();
        Create2Deployer dc = Create2Deployer(deployParams.deployerContract);
        dc.deploy(type(ProfileDeployer).creationCode, SALT);
        vm.stopBroadcast();
    }
}
