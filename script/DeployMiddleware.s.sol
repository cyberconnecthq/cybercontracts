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
            LibDeploy.deployAllMiddleware(
                vm,
                LibDeploy.DeployParams(true, true, deployParams),
                address(0x47C282Bef1dE396Defd13878859B580636b81796), // engine proxy address
                address(0xB9d6D688E1e051CB74E5B5d1627421De56F2B4aD), // cyber treasury address
                true
            );
        } else if (block.chainid == 97) {
            LibDeploy.deployAllMiddleware(
                vm,
                LibDeploy.DeployParams(true, true, deployParams),
                address(0x7294aB1F2C1601c3da46499574e16078a42c8056), // engine proxy address
                address(0xD3BF7Ac52482164D9176892c41eC083C735f983e), // cyber treasury address
                true
            );
        }
        vm.stopBroadcast();
    }
}
