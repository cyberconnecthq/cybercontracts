// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { ProfileNFT } from "../src/core/ProfileNFT.sol";
import { CyberEngine } from "../src/core/CyberEngine.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";
import { PermissionedFeeCreationMw } from "../src/middlewares/profile/PermissionedFeeCreationMw.sol";

contract TempScript is Script {
    function run() external {
        // vm.startBroadcast();
        ProfileNFT profile = ProfileNFT(
            0x5A1Bd07533677D389EcAd9C4B1C5D8A3bce99418
        );
        CyberEngine engine = CyberEngine(
            0xE8805326f9DA84e70c680429eD46B924b3F158F2
        );
        PermissionedFeeCreationMw mw = PermissionedFeeCreationMw(
            0x70FEb3686075b7f99b9D4C1e8238bBEA995292F1
        );
        address link3Treasury = address(
            0xe75Fe33b0fB1441a11C5c1296e5Ca83B72cfE00d
        );
        address link3Signer = address(
            0x2A2EA826102c067ECE82Bc6E2B7cf38D7EbB1B82
        );

        // engine.setProfileMw(
        //     address(profile),
        //     address(mw),
        //     abi.encode(
        //         link3Signer,
        //         link3Treasury,
        //         LibDeploy._INITIAL_FEE_TIER0,
        //         LibDeploy._INITIAL_FEE_TIER1,
        //         LibDeploy._INITIAL_FEE_TIER2,
        //         LibDeploy._INITIAL_FEE_TIER3,
        //         LibDeploy._INITIAL_FEE_TIER4,
        //         LibDeploy._INITIAL_FEE_TIER5
        //     )
        // );
        console.log(mw.getSigner(address(profile)));

        // vm.stopBroadcast();
    }
}
