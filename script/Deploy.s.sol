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
            0x70f433251AEBbf404796dB99864792eC14024F4D
        );
        string
            memory templateURL = "https://cyberconnect.mypinata.cloud/ipfs/bafkreieyuwfk4zuaibbx457n5od5n3drkyyqga7fp7bexdxzg2dfpzv7xq";

        LibDeploy.deploy(msg.sender, nonce, templateURL);
        // TODO: set correct role capacity
        // TODO: do a health check. verify everything
        vm.stopBroadcast();
    }
}
