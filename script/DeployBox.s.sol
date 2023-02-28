// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract DeployScript is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();
        if (block.chainid == DeploySetting.MAINNET) {
            LibDeploy.deployBox(
                vm,
                deployParams.deployerContract,
                deployParams.link3Owner,
                deployParams.link3Owner, // owner address
                true
            );
        } else if (block.chainid == DeploySetting.BNBT) {
            LibDeploy.deployBox(
                vm,
                deployParams.deployerContract,
                deployParams.link3Signer,
                deployParams.link3Owner, // owner address
                true
            );
        } else if (block.chainid == DeploySetting.BNB) {
            LibDeploy.deployBox(
                vm,
                deployParams.deployerContract,
                deployParams.link3Signer,
                address(0xf9E12df9428F1a15BC6CfD4092ADdD683738cE96), // owner address - safe
                true
            );
        }

        vm.stopBroadcast();
    }
}
