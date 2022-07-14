// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { ProfileNFT } from "../../../src/core/ProfileNFT.sol";
import { Link3ProfileDescriptor } from "../../../src/periphery/Link3ProfileDescriptor.sol";
import { Create2Deployer } from "../../libraries/Create2Deployer.sol";
import { LibDeploy } from "../../libraries/LibDeploy.sol";

contract SetAnimationURL is Script {
    address internal link3Profile = 0x0Ea8A473f149c03E38C5787158276854489fD0b1;
    string internal animationUrl =
        "https://cyberconnect.mypinata.cloud/ipfs/bafkreiejm7as3aw6en6vxejxma55eaasfkbsc3ii5vacahudgqf5wh7pfu";

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
