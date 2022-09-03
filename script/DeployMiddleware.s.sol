// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract DeployScript is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();
        LibDeploy.deployAllMiddleware(
            vm,
            LibDeploy.DeployParams(true, true, deployParams),
            address(0x47C282Bef1dE396Defd13878859B580636b81796), // engine proxy address
            address(0xB9d6D688E1e051CB74E5B5d1627421De56F2B4aD), // cyber treasury address
            true
        );
        vm.stopBroadcast();
    }
}
