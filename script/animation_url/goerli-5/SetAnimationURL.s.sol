// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { ProfileNFT } from "../../../src/core/ProfileNFT.sol";
import { Link3ProfileDescriptor } from "../../../src/periphery/Link3ProfileDescriptor.sol";
import { Create2Deployer } from "../../libraries/Create2Deployer.sol";
import { LibDeploy } from "../../libraries/LibDeploy.sol";
import { DeploySetting } from "../../libraries/DeploySetting.sol";

contract SetAnimationURL is Script, DeploySetting {
    address internal link3Profile = 0x5A1Bd07533677D389EcAd9C4B1C5D8A3bce99418;
    string internal animationUrl =
        "https://cyberconnect.mypinata.cloud/ipfs/bafkreicy67254phsl53lqwwbg4fzorhjubapxa4jo3ossvmkwzdsybzf54";

    function run() external {
        _setDeployParams();
        // make sure only on anvil
        require(block.chainid == 5, "ONLY_GOERLI");
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
