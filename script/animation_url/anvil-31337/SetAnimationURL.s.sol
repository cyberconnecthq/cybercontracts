// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { ProfileNFT } from "../../../src/core/ProfileNFT.sol";
import { Link3ProfileDescriptor } from "../../../src/periphery/Link3ProfileDescriptor.sol";
import { Create2Deployer } from "../../libraries/Create2Deployer.sol";
import { LibDeploy } from "../../libraries/LibDeploy.sol";

contract SetAnimationURL is Script {
    address internal link3Profile = 0x56aD3f7e5E3Eb0B00b57e6985C136d4a0Be955D2;
    string internal animationUrl =
        "https://cyberconnect.mypinata.cloud/ipfs/bafkreicokyglb6hpzv3nzjgp2wq3ftcpq6a7faslzlyakp5v7p32rjpgiu";

    function run() external {
        // make sure only on anvil
        address deployerContract = 0xC7f2Cf4845C6db0e1a1e91ED41Bcd0FcC1b0E141;
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
