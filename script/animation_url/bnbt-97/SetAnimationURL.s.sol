// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { ProfileNFT } from "../../../src/core/ProfileNFT.sol";
import { Link3ProfileDescriptor } from "../../../src/periphery/Link3ProfileDescriptor.sol";
import { Create2Deployer } from "../../../src/deployer/Create2Deployer.sol";
import { LibDeploy } from "../../libraries/LibDeploy.sol";
import { DeploySetting } from "../../libraries/DeploySetting.sol";

contract SetAnimationURL is Script, DeploySetting {
    address internal link3Profile = 0x57e12b7a5F38A7F9c23eBD0400e6E53F2a45F271;
    string internal animationUrl =
        "https://cyberconnect.mypinata.cloud/ipfs/bafkreigqqa3tkzqkl7bjylkya5nf5qsyyjcunsp4ix525icn5nycf7nw2m";

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
