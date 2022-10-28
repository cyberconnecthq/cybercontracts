// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";

contract DeployScript is Script, DeploySetting {
    function run() external {
        _setDeployParams();

        vm.startBroadcast();
        if (block.chainid == DeploySetting.MAINNET) {
            LibDeploy.setAniURL(
                vm,
                LibDeploy.DeployParams(true, true, deployParams),
                address(0x818CBEE6081ae4C89caBc642Ac2542b2585F68Bb) // link3 descriptor
            );
        }

        vm.stopBroadcast();
    }
}
