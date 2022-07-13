// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { ProfileNFT } from "../../../src/core/ProfileNFT.sol";
import { Link3ProfileDescriptor } from "../../../src/periphery/Link3ProfileDescriptor.sol";
import { Create2Deployer } from "../../libraries/Create2Deployer.sol";
import { LibDeploy } from "../../libraries/LibDeploy.sol";

contract SetAnimationURL is Script {
    address internal link3Profile = ;
    string internal animationUrl = "https://cyberconnect.mypinata.cloud/ipfs/bafkreihxi4ce5xcax43vkchm6thmajivxh7ecnihn4kvqwo4sz5x2cngfm";

    function run() external {
        // make sure only on anvil
        address deployerContract = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
        require(block.chainid == 31337, "ONLY_ANVIL");
        vm.startBroadcast();

        LibDeploy.deployLink3Descriptor(
            vm,
            deployerContract,
            true,
            animationUrl,
            link3Profile
        );

        vm.stopBroadcast();
    }
}
