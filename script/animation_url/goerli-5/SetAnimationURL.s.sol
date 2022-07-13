// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { ProfileNFT } from "../../../src/core/ProfileNFT.sol";
import { Link3ProfileDescriptor } from "../../../src/periphery/Link3ProfileDescriptor.sol";
import { Create2Deployer } from "../../libraries/Create2Deployer.sol";
import { LibDeploy } from "../../libraries/LibDeploy.sol";

contract SetAnimationURL is Script {
    address internal link3Profile = 0xAB58CF38affa74bd5241329b52500B7B7959a3dA;
    address internal link3Auth = 0x63e0C38bfc9589B927209553207cEEE1A5dA136B;
    string internal animationUrl =
        "https://cyberconnect.mypinata.cloud/ipfs/bafkreihln4qdux62nnp5ghdga3m7tegi3ylwx5sgeuwujs52hma7qex4xu";
    Create2Deployer dc = Create2Deployer(address(0));

    function run() external {
        // make sure only on anvil
        address deployerContract = 0xdB94815F9D2f5A647c8D96124C7C1d1b42a23B47;
        require(block.chainid == 5, "ONLY_GOERLI");
        vm.startBroadcast();

        LibDeploy.deployLink3Descriptor(
            vm,
            deployerContract,
            true,
            animationUrl,
            link3Profile,
            link3Auth
        );

        vm.stopBroadcast();
    }
}
