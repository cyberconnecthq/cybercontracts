// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";

contract SetAnimationURLV2 is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        if (block.chainid == DeploySetting.MAINNET) {
            LibDeploy.deployLink3DescriptorV2(
                vm,
                deployParams.deployerContract,
                true,
                address(0x8CC6517e45dB7a0803feF220D9b577326A12033f), // link3Profile
                deployParams.link3Owner
            );
        } else if (block.chainid == DeploySetting.BNBT) {
            LibDeploy.deployLink3DescriptorV2(
                vm,
                deployParams.deployerContract,
                true,
                address(0x57e12b7a5F38A7F9c23eBD0400e6E53F2a45F271), // link3Profile
                deployParams.link3Owner
            );
        } else if (block.chainid == DeploySetting.BNB) {
            LibDeploy.deployLink3DescriptorV2(
                vm,
                deployParams.deployerContract,
                true,
                address(0x2723522702093601e6360CAe665518C4f63e9dA6), // link3Profile
                deployParams.link3Owner
            );
        }

        vm.stopBroadcast();
    }
}
