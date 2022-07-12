// SPDX-License-Identifier: GPL-3.0-or-later

// AUTO-GENERATED
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
            0x1E9eb6311E54acF922badC20B0564ffa2c549bBF
        );
        string
            memory templateURL = "https://cyberconnect.mypinata.cloud/ipfs/bafkreid6ny6ihdezwqylwongnchdvgkuo5y4q6fylxfzmor4luyelndb5e";

        LibDeploy.deploy(msg.sender, nonce, templateURL);
        // TODO: set correct role capacity
        // TODO: do a health check. verify everything
        vm.stopBroadcast();
    }
}
