// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { ProfileNFT } from "../src/core/ProfileNFT.sol";
import { CyberEngine } from "../src/core/CyberEngine.sol";
import { CyberGrandNFT } from "../src/periphery/CyberGrandNFT.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";
import { PermissionedFeeCreationMw } from "../src/middlewares/profile/PermissionedFeeCreationMw.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();
        address deployer = 0x39e0c6E610A8D7F408dD688011591583cbc1c3ce;
        require(msg.sender == deployer);

        address signer = 0x2A2EA826102c067ECE82Bc6E2B7cf38D7EbB1B82;
        address grandProxy = 0x09E1d96D9B4bA7d2dfB7Ac543E53f27f85317274;

        require(
            CyberGrandNFT(grandProxy).getSigner() == deployer,
            "WRONG_SIGNER"
        );

        CyberGrandNFT(grandProxy).setSigner(signer);

        require(
            CyberGrandNFT(grandProxy).getSigner() == signer,
            "WRONG_SIGNER"
        );

        vm.stopBroadcast();
    }
}
