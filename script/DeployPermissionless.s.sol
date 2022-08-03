// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeployNamespace } from "./libraries/DeployNamespace.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";

contract DeployPermissionlessScript is Script {
    DeployNamespace.DeployNamespaceParams params;

    function _setup() private {
        if (block.chainid == 5) {
            params.engineProxy = 0xadAEc1655D34c9E86394400e1cdEF3BaC3F0C117;
            params.namespaceOwner = 0x927f355117721e0E8A7b5eA20002b65B8a551890;
            params.name = "CyberConnect";
            params.symbol = "CYBER";
            params.profileFac = 0x5eB4f4d2b4A2C0E331e1c1767143EfcB91Bf56e7;
            params.subFac = 0xa97a8F309263658B77a2755be861173fB633020d;
            params.essFac = 0xcfB865f5F4a3c74cc2CAC0460273BB43f3D8E27C;
        }
    }

    function run() external {
        _setup();
        vm.startBroadcast();

        DeployNamespace.deployNamespace(vm, params);
        vm.stopBroadcast();
    }
}
