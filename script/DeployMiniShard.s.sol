// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract DeployScript is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        if (block.chainid == DeploySetting.BNBT) {
            LibDeploy.deployMiniShard(
                vm,
                deployParams.deployerContract,
                deployParams.link3Signer,
                "https://mb-metadata.cyberconnect.dev/minishards",
                true
            );
        } else if (block.chainid == BNB) {
            LibDeploy.deployMiniShard(
                vm,
                deployParams.deployerContract,
                deployParams.link3Signer,
                "https://mbmetadata.cyberconnect.dev/minishards",
                true
            );
        } else if (block.chainid == POLYGON) {
            LibDeploy.deployMiniShard(
                vm,
                deployParams.deployerContract,
                deployParams.link3Signer,
                "https://mbmetadata.cyberconnect.dev/minishards-polygon",
                true
            );
        }
        vm.stopBroadcast();
    }
}
