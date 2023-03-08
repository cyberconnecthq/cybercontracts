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
            LibDeploy.allowCurrency(
                vm,
                address(0x3963744012daDf90A9034Ea1068f53108B1A3834), // Treasury Address
                address(0x326C977E6efc84E512bB9C30f76E30c160eD06FB) // Currency Address
            );
        } else if (block.chainid == DeploySetting.BNB) {
            LibDeploy.allowCurrency(
                vm,
                address(0x90137F1234C137C4284dd317303F2717c871f70A), // Treasury Address
                address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56) // Currency Address
            );
        }
        vm.stopBroadcast();
    }
}
