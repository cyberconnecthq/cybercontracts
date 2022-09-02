// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { ProfileNFT } from "../../../src/core/ProfileNFT.sol";
import { Link3ProfileDescriptor } from "../../../src/periphery/Link3ProfileDescriptor.sol";
import { Create2Deployer } from "../../../src/deployer/Create2Deployer.sol";
import { LibDeploy } from "../../libraries/LibDeploy.sol";
import { DeploySetting } from "../../libraries/DeploySetting.sol";

contract SetAnimationURL is Script, DeploySetting {
    address internal link3Profile = 0x8CC6517e45dB7a0803feF220D9b577326A12033f;
    string internal animationUrl =
        "https://cyberconnect.mypinata.cloud/ipfs/bafkreidztiie5tmfvadt52nnb4q2g2whglrnsyhyk7d43hwczh65xjtwni";

    function run() external {
        _setDeployParams();
        // make sure only on anvil
        require(block.chainid == 1, "ONLY_MAINNET");
        vm.startBroadcast();

        LibDeploy.deployLink3Descriptor(
            vm,
            deployParams.deployerContract,
            true,
            animationUrl,
            link3Profile,
            deployParams.link3Owner
        );

        vm.stopBroadcast();
    }
}
