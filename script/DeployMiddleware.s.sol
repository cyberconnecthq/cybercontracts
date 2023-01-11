// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract DeployScript is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();
        if (
            block.chainid == DeploySetting.BNBT ||
            block.chainid == DeploySetting.GOERLI
        ) {
            LibDeploy.deployAllMiddleware(
                vm,
                LibDeploy.DeployParams(true, true, deployParams),
                address(0xAF9104Eb9c6B21Efdc43BaaaeE70662d6CcE8798), // engine proxy address
                address(0x3963744012daDf90A9034Ea1068f53108B1A3834), // cyber treasury address
                true
            );
        } else if (
            block.chainid == DeploySetting.BNB ||
            block.chainid == DeploySetting.NOVA
        ) {
            LibDeploy.deployAllMiddleware(
                vm,
                LibDeploy.DeployParams(true, true, deployParams),
                address(0x24Ee18a7135020E02C18DaD07e201C44e7d68334), // engine proxy address
                address(0x4a4712D9AC10bAfEe113A070019c2b342eAac2fA), // cyber treasury address
                true
            );
        } else if (block.chainid == DeploySetting.POLYGON) {
            LibDeploy.deployAllMiddleware(
                vm,
                LibDeploy.DeployParams(true, true, deployParams),
                address(0x346Bf45A74e1B9d31E0E5d747964f99c81FFFfD8), // engine proxy address
                address(0x2E51d648B862A8A8733567Ac6e1C765343809248), // cyber treasury address
                true
            );
        }
        vm.stopBroadcast();
    }
}
