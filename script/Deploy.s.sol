// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract DeployScript is Script {
    function run() external {
        // HACK: https://github.com/foundry-rs/foundry/issues/2110
        uint256 nonce = vm.getNonce(msg.sender);
        console.log("vm.getNonce", vm.getNonce(msg.sender));
        vm.startBroadcast();

        LibDeploy.deploy(msg.sender, nonce);
        // TODO: set correct role capacity
        // TODO: do a health check. verify everything
        vm.stopBroadcast();
    }
}
