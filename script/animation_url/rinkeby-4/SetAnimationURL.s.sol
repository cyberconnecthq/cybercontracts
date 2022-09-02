// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { ProfileNFT } from "../../../src/core/ProfileNFT.sol";
import { Link3ProfileDescriptor } from "../../../src/periphery/Link3ProfileDescriptor.sol";
import { Create2Deployer } from "../../../src/deployer/Create2Deployer.sol";
import { LibDeploy } from "../../libraries/LibDeploy.sol";
import { DeploySetting } from "../../libraries/DeploySetting.sol";

contract SetAnimationURL is Script, DeploySetting {
    address internal link3Profile = 0xb9FDA6C1C56dC7AC3aE787a46fD3434DA991626D;
    string internal animationUrl =
        "https://cyberconnect.mypinata.cloud/ipfs/bafkreifq5vu6gl4q4c5fb23m5w3wyijumonpfb7dki7eodx2222ogfb3lu";

    function run() external {
        _setDeployParams();
        // make sure only on anvil
        require(block.chainid == 4, "ONLY_RINKEBY");
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
