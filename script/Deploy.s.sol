// SPDX-License-Identifier: GPL-3.0-or-later
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
            0xDb7f2e6c5aFe48232e268964bD0Ab932B46d9bBa
        );
        string
            memory templateURL = "https://cyberconnect.mypinata.cloud/ipfs/bafkreiau22w2k7meawcll2ibwbzmjx5szatzhbkhmmsfmh5van33szczbq";

        LibDeploy.deploy(msg.sender, nonce, templateURL);
        // TODO: set correct role capacity
        // TODO: do a health check. verify everything
        vm.stopBroadcast();
    }
}
