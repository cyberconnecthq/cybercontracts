// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { ProfileNFT } from "../src/core/ProfileNFT.sol";
import { CyberEngine } from "../src/core/CyberEngine.sol";
import { CyberBoxNFT } from "../src/periphery/CyberBoxNFT.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";
import { PermissionedFeeCreationMw } from "../src/middlewares/profile/PermissionedFeeCreationMw.sol";

contract SetSignerScript is Script {
    function run() external {
        vm.startBroadcast();
        address deployer = 0x39e0c6E610A8D7F408dD688011591583cbc1c3ce;
        require(msg.sender == deployer);
        address signer = 0xaB24749c622AF8FC567CA2b4d3EC53019F83dB8F;
        address box = 0xcE4F341622340d56E397740d325Fd357E62b91CB;
        require(CyberBoxNFT(box).owner() == deployer);

        CyberBoxNFT(box).setSigner(signer);
        vm.stopBroadcast();
    }
}
