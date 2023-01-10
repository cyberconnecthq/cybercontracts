// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { ProfileNFT } from "../../../src/core/ProfileNFT.sol";
import { Link3ProfileDescriptor } from "../../../src/periphery/Link3ProfileDescriptor.sol";
import { Create2Deployer } from "../../../src/deployer/Create2Deployer.sol";
import { LibDeploy } from "../../libraries/LibDeploy.sol";
import { DeploySetting } from "../../libraries/DeploySetting.sol";

contract SetAnimationURL is Script, DeploySetting {
    address internal link3Profile = 0xE2f8a9885E81429f1B464b01a1EA234293474945;
    string internal animationUrl =
        "https://cyberconnect.mypinata.cloud/ipfs/bafkreiebcj2it5hirwrfbfhjlwr7pxbjqvojtxht4bcjhvvnjxqwomqqly";

    function run() external {
        _setDeployParams();
        // make sure only on anvil
        require(block.chainid == 137, "ONLY_POLYGON");
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
