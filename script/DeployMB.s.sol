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
                "https://mb-metadata.cyberconnect.dev",
                true
            );
        } else if (block.chainid == DeploySetting.MAINNET) {
            LibDeploy.deployMB(
                vm,
                deployParams.deployerContract,
                deployParams.link3Owner,
                address(0xcE4F341622340d56E397740d325Fd357E62b91CB),
                "https://mbmetadata.cyberconnect.dev",
                true
            );
        } else if (block.chainid == DeploySetting.BNB) {
            LibDeploy.deployMB(
                vm,
                deployParams.deployerContract,
                address(0xf9E12df9428F1a15BC6CfD4092ADdD683738cE96), // owner address - safe
                address(0xCAdC6C364E8fcad0F382FDdfd6ff5b41d82EB3e4),
                "https://mbmetadata.cyberconnect.dev/bnb",
                true
            );
        } else if (block.chainid == DeploySetting.BNBT) {
            LibDeploy.deployMB(
                vm,
                deployParams.deployerContract,
                deployParams.link3Owner,
                address(0x54346edD22ef49bdcA1aaE6114F8B1a1E598b674),
                "https://mb-metadata.cyberconnect.dev/bnb",
                true
            );
        }
        vm.stopBroadcast();
    }
}
