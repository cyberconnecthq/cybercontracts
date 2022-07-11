// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "./libraries/Create2Deployer.sol";

contract DeployerCreate2Deployer is Script {
    function run() external {
        vm.startBroadcast();
        new Create2Deployer();
        vm.stopBroadcast();
    }
}
