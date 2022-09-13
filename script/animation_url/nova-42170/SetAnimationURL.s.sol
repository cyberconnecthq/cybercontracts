// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { ProfileNFT } from "../../../src/core/ProfileNFT.sol";
import { Link3ProfileDescriptor } from "../../../src/periphery/Link3ProfileDescriptor.sol";
import { Create2Deployer } from "../../../src/deployer/Create2Deployer.sol";
import { LibDeploy } from "../../libraries/LibDeploy.sol";
import { DeploySetting } from "../../libraries/DeploySetting.sol";

contract SetAnimationURL is Script, DeploySetting {
    address internal link3Profile = 0x2723522702093601e6360CAe665518C4f63e9dA6;
    string internal animationUrl =
        "https://cyberconnect.mypinata.cloud/ipfs/bafkreiaiurmd4gpnu4nqjlddbt2r57ipshpsz77bf7mybun36psiggrbui";

    function run() external {
        _setDeployParams();
        // make sure only on anvil
        require(block.chainid == 42170, "ONLY_NOVA");
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
