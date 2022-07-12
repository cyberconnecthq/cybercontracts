// SPDX-License-Identifier: GPL-3.0-or-later

// AUTO-GENERATED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

// 16 Transaction + 3 Transaction to mint a test profile
contract DeployScript is Script {
    function run() external {
        // TODO: this is Rinkeby address, change for prod
        address deployerContract = 0x84aE5cA42f688d08F9E8cC0dB18e09Fe91f90bAc;
        if (block.chainid == 31337) {
            deployerContract = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
        }
        uint256 nonce = vm.getNonce(msg.sender);
        console.log("vm.getNonce", vm.getNonce(msg.sender));
        vm.startBroadcast();
        string
            memory templateURL = "https://cyberconnect.mypinata.cloud/ipfs/bafkreic7v6ca23rht5pudfqneoftw4dlnw3gy7dvv6fojwerfjm2hii5dy";

        LibDeploy.deploy(vm, msg.sender, nonce, templateURL, deployerContract);
        // TODO: set correct role capacity
        // TODO: do a health check. verify everything
        vm.stopBroadcast();
    }
}
