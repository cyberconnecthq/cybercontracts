// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { ProfileNFT } from "../src/core/ProfileNFT.sol";
import { CyberEngine } from "../src/core/CyberEngine.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";
import { PermissionedFeeCreationMw } from "../src/middlewares/profile/PermissionedFeeCreationMw.sol";

contract TempScript is Script {
    function run() external {
        address engineProxy = address(
            0xE8805326f9DA84e70c680429eD46B924b3F158F2
        );
        address link3Profile = address(
            0x8CC6517e45dB7a0803feF220D9b577326A12033f
        );
        console.log(
            CyberEngine(engineProxy).getProfileMwByNamespace((link3Profile))
        );
        console.log(ProfileNFT(link3Profile).getAvatar(4));
        console.log(ProfileNFT(link3Profile).getMetadata(4));
        console.log(ProfileNFT(link3Profile).tokenURI(4));
        console.log(ProfileNFT(link3Profile).getHandleByProfileId(4));
    }
}
