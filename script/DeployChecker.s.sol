// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract DeployScript is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        if (block.chainid == DeploySetting.GOERLI) {
            LibDeploy.deployRelationshipChecker(
                vm,
                LibDeploy.DeployParams(true, true, deployParams),
                address(0x57e12b7a5F38A7F9c23eBD0400e6E53F2a45F271), // link3 namespace
                true
            );
        }
        vm.stopBroadcast();
    }
}
