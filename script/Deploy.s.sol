// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract DeployScript is Script {
    function run() external {
        // HACK: https://github.com/foundry-rs/foundry/issues/2110
        uint256 nonce = vm.getNonce(msg.sender);
        console.log("vm.getNonce", vm.getNonce(msg.sender));
        vm.startBroadcast();

        address profileProxy = address(
            0xE325EBc97236e0b62D0166094186d968ab86c8E1
        );
        string
            memory templateURL = "https://cyberconnect.mypinata.cloud/ipfs/bafkreifp336f6sfergcmgt5bqrdhtuo3wdexgxlefnbutc4jsds7xubv3y";

        LibDeploy.deploy(msg.sender, nonce, templateURL);
        // TODO: set correct role capacity
        // TODO: do a health check. verify everything
        vm.stopBroadcast();
    }
}
