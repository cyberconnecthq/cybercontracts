// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { ProfileNFT } from "../../../src/core/ProfileNFT.sol";
import { Link3ProfileDescriptor } from "../../../src/periphery/Link3ProfileDescriptor.sol";
import { Create2Deployer } from "../../../src/deployer/Create2Deployer.sol";
import { LibDeploy } from "../../libraries/LibDeploy.sol";
import { DeploySetting } from "../../libraries/DeploySetting.sol";

contract SetAnimationURL is Script, DeploySetting {
    address internal link3Profile = 0x84009d423898B1c371b4515fa6540A922fF5e40a;
    string internal animationUrl =
        "https://cyberconnect.mypinata.cloud/ipfs/bafkreifjwei5tuvh5zjk7r6ti4wt7eon7dwnobchdinfmdzqhl2l2lrgve";

    function run() external {
        _setDeployParams();
        // make sure only on anvil
        address deployerContract = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
        require(block.chainid == 31337, "ONLY_ANVIL");
        vm.startBroadcast();

        LibDeploy.deployLink3Descriptor(
            vm,
            deployerContract,
            true,
            animationUrl,
            link3Profile,
            deployParams.link3Owner
        );

        vm.stopBroadcast();
    }
}
