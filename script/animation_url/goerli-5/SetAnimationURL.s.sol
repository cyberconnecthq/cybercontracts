// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { ProfileNFT } from "../../../src/core/ProfileNFT.sol";
import { Link3ProfileDescriptor } from "../../../src/periphery/Link3ProfileDescriptor.sol";
import { Create2Deployer } from "../../libraries/Create2Deployer.sol";
import { LibDeploy } from "../../libraries/LibDeploy.sol";

contract SetAnimationURL is Script {
    address internal link3Profile = 0xF739B940edcff9228edFDA83664a7584E170DC75;
    string internal animationUrl =
        "https://cyberconnect.mypinata.cloud/ipfs/bafkreih27a523fdqmb2b2t3wlq6xtkamxsq2gw2ll3ste4gi3rmvigi5xi";
    Create2Deployer dc = Create2Deployer(address(0));

    function run() external {
        // make sure only on anvil
        address deployerContract = 0xF8bD428a025ecB629E6d963ec78399587682FE14;
        require(block.chainid == 5, "ONLY_GOERLI");
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
