// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";
import { Create2Deployer } from "./libraries/Create2Deployer.sol";

// 16 Transaction + 3 Transaction to mint a test profile
contract DeployScript is Script {
    function run() external {
        // TODO: this is Rinkeby address, change for prod
        address deployerContract = 0x84aE5cA42f688d08F9E8cC0dB18e09Fe91f90bAc;
        if (block.chainid == 31337) {
            deployerContract = address(
                0xC7f2Cf4845C6db0e1a1e91ED41Bcd0FcC1b0E141
            );
            if (deployerContract.code.length == 0) {
                address deployer = address(new Create2Deployer());
                console.log(deployer);
                require(
                    deployer == deployerContract,
                    "DEPLOYER_WRONG_FOR_ANVIL"
                );
            }
        }
        uint256 nonce = vm.getNonce(msg.sender);
        console.log("vm.getNonce", vm.getNonce(msg.sender));
        vm.startBroadcast();

        LibDeploy.deploy(vm, msg.sender, nonce, deployerContract, true);

        vm.stopBroadcast();
    }
}
