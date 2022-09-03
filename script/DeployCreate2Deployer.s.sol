// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/deployer/Create2Deployer.sol";

contract DeployerCreate2Deployer is Script {
    function run() external {
        uint256 nonce = vm.getNonce(msg.sender);
        if (block.chainid == 1 || block.chainid == 56) {
            require(nonce == 0, "nonce must be 0");
            console.log("deployer", msg.sender);
            require(
                msg.sender == 0xA7b6bEf855c1c57Df5b7C9c7a4e1eB757e544e7f,
                "address must be deployer"
            );
        }

        vm.startBroadcast();
        new Create2Deployer();
        vm.stopBroadcast();
    }
}
