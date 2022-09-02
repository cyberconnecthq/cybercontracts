// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "./libraries/Create2Deployer.sol";

contract DeployerCreate2Deployer is Script {
    function run() external {
        uint256 nonce = vm.getNonce(msg.sender);
        require(nonce == 0, "nonce must be 0");
        console.log("deployer", msg.sender);
        require(
            msg.sender == 0x927f355117721e0E8A7b5eA20002b65B8a551890,
            "address must be deployer"
        );
        vm.startBroadcast();
        new Create2Deployer();
        vm.stopBroadcast();
    }
}
