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
                address(0x994d90C72aD3eeB327b6f6288D544384eF53a020), // desc proxy
                address(0xB9d6D688E1e051CB74E5B5d1627421De56F2B4aD) // treasury proxy
            );
        } else if (block.chainid == 1) {
            address timelock = LibDeploy.deployTimeLock(
                vm,
                deployParams.cyberTokenOwner,
                48 * 3600,
                true
            );
            LibDeploy.changeOwnership(
                vm,
                timelock,
                deployParams.engineGov,
                address(0x5cf03F4997AFa9A94506990D24c12D6aBaD61E6F), // role auth
                address(0xcE4F341622340d56E397740d325Fd357E62b91CB), // box proxy
                address(0x818CBEE6081ae4C89caBc642Ac2542b2585F68Bb), // desc proxy
                address(0x5DA0eD64A9868d128F8d6f56dC78B727F85ff2D0) // treasury proxy
            );
        }
        vm.stopBroadcast();
    }
}
