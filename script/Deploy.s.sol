// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";
import { ProfileNFT } from "../src/core/ProfileNFT.sol";
import { CyberEngine } from "../src/core/CyberEngine.sol";
import { PermissionedFeeCreationMw } from "../src/middlewares/profile/PermissionedFeeCreationMw.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";

contract DeployScript is Script, DeploySetting {
    function run() external {
        _setDeployParams();

        console.log("vm.getNonce", vm.getNonce(msg.sender));
        vm.startBroadcast();

        LibDeploy.deploy(
            vm,
            LibDeploy.DeployParams(
                true,
                deployParams.deployerContract,
                true,
                deployParams.link3Owner,
                deployParams.link3Signer,
                deployParams.engineAuthOwner,
                deployParams.engineGov,
                deployParams.link3Signer
            )
        );

        vm.stopBroadcast();
    }
}
