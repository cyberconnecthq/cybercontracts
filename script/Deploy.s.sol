// SPDX-License-Identifier: GPL-3.0-or-later

// AUTO-GENERATED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

// 16 Transaction + 3 Transaction to mint a test profile
contract DeployScript is Script {
    function run() external {
        // TODO: this is Rinkeby address, change for prod
        address deployerContract;
        if (block.chainid == 31337) {
            // deployerContract = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
        } else if (block.chainid == 4) {
            deployerContract = 0x1202F1AAe12d3fcBFB9320eE2396c19f93581f41;
        } else if (block.chainid == 5) {
            // deployerContract = 0xdB94815F9D2f5A647c8D96124C7C1d1b42a23B47;
        }
        // require(deployerContract != address(0), "DEPLOYER_CONTRACT_NOT_SET");
        uint256 nonce = vm.getNonce(msg.sender);
        console.log("vm.getNonce", vm.getNonce(msg.sender));
        vm.startBroadcast();

        LibDeploy.deploy(vm, msg.sender, nonce, deployerContract, true);
        // TODO: set correct role capacity
        // TODO: do a health check. verify everything
        vm.stopBroadcast();
    }
}
