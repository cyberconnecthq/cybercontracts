// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";

contract SetAnimationURLV2 is Script, DeploySetting {
    address internal link3Profile = 0x8CC6517e45dB7a0803feF220D9b577326A12033f;

    function run() external {
        _setDeployParams();
        // make sure only on anvil
        require(block.chainid == 1, "ONLY_MAINNET");
        vm.startBroadcast();

        LibDeploy.deployLink3DescriptorV2(
            vm,
            deployParams.deployerContract,
            true,
            link3Profile,
            deployParams.link3Owner
        );

        vm.stopBroadcast();
    }
}
