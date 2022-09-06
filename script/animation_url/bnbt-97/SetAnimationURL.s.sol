// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { ProfileNFT } from "../../../src/core/ProfileNFT.sol";
import { Link3ProfileDescriptor } from "../../../src/periphery/Link3ProfileDescriptor.sol";
import { Create2Deployer } from "../../../src/deployer/Create2Deployer.sol";
import { LibDeploy } from "../../libraries/LibDeploy.sol";
import { DeploySetting } from "../../libraries/DeploySetting.sol";

contract SetAnimationURL is Script, DeploySetting {
    address internal link3Profile = 0xc633795bE5E61F0363e239fC21cF32dbB073Fd21;
    string internal animationUrl =
        "https://cyberconnect.mypinata.cloud/ipfs/bafkreib2yuwweek3gri3kilcbwhiimzvgwrur5qibinzctwh7uhdha4eku";

    function run() external {
        _setDeployParams();
        // make sure only on anvil
        require(block.chainid == 97, "ONLY_BNBT");
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
