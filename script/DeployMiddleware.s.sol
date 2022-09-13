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
                address(0xAF9104Eb9c6B21Efdc43BaaaeE70662d6CcE8798), // engine proxy address
                address(0x3963744012daDf90A9034Ea1068f53108B1A3834), // cyber treasury address
                true
            );
        } else if (block.chainid == 56) {
            LibDeploy.deployAllMiddleware(
                vm,
                LibDeploy.DeployParams(true, true, deployParams),
                address(0x1cA51941a616D14C42D3e3B9E6E687d7F5054c3A), // engine proxy address
                address(0x90137F1234C137C4284dd317303F2717c871f70A), // cyber treasury address
                true
            );
        }
        vm.stopBroadcast();
    }
}
