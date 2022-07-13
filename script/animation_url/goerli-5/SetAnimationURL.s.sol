// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { ProfileNFT } from "../../../src/core/ProfileNFT.sol";
import { Link3ProfileDescriptor } from "../../../src/periphery/Link3ProfileDescriptor.sol";
import { Create2Deployer } from "../../libraries/Create2Deployer.sol";
import { LibDeploy } from "../../libraries/LibDeploy.sol";

contract SetAnimationURL is Script {
    address internal link3Profile = 0xAaF7d83C1F5092c5d003221cB20eb0f6b673e8C6;
    string internal animationUrl = "https://cyberconnect.mypinata.cloud/ipfs/bafkreievmy6ilyeovkqgvxo5ivk6vrbo6yx6ti2sqm3mmyy45sokxaxwdm";
    Create2Deployer dc = Create2Deployer(address(0));

    function run() external {
        // make sure only on anvil
        address deployerContract = 0xdB94815F9D2f5A647c8D96124C7C1d1b42a23B47;
        require(block.chainid == 31337, "ONLY_RINKEBY");
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
