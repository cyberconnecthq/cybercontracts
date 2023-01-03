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
            LibDeploy.deployMB(
                vm,
                deployParams.deployerContract,
                deployParams.link3Owner,
                address(0x1cC24A44c4b51D3F9B0d0F5BdCF95b0F385B154f),
                true
            );
        }
        vm.stopBroadcast();
    }
}
