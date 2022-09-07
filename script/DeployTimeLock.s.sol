// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract DeployScript is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        if (block.chainid == 5) {
            address timelock = LibDeploy.deployTimeLock(
                vm,
                deployParams.link3Owner,
                600,
                true
            );
            LibDeploy.changeOwnership(
                vm,
                timelock,
                deployParams.engineGov,
                address(0x12F7bBc1A79ECA365F9A833a298E6684458F93bF), // role auth
                address(0x1Dfc23a9A81202980711A334B07038A9A1789d73), // box proxy
                address(0x994d90C72aD3eeB327b6f6288D544384eF53a020) // desc proxy
            );
        }
        vm.stopBroadcast();
    }
}
