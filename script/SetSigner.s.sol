// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { ProfileNFT } from "../src/core/ProfileNFT.sol";
import { CyberEngine } from "../src/core/CyberEngine.sol";
import { CyberBoxNFT } from "../src/periphery/CyberBoxNFT.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";
import { PermissionedFeeCreationMw } from "../src/middlewares/profile/PermissionedFeeCreationMw.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();
        // address deployer = 0x39e0c6E610A8D7F408dD688011591583cbc1c3ce;
        // require(msg.sender == deployer);

        // address signer = 0x2A2EA826102c067ECE82Bc6E2B7cf38D7EbB1B82;
        address boxProxy = 0xcE4F341622340d56E397740d325Fd357E62b91CB;

        require(CyberBoxNFT(boxProxy).paused() == true, "GRAND_NFT_NOT_PAUSED");

        CyberBoxNFT(boxProxy).pause(false);

        require(CyberBoxNFT(boxProxy).paused() == false, "GRAND_NFT_PAUSED");

        vm.stopBroadcast();
    }
}
