// SPDX-License-Identifier: GPL-3.0-or-later

// AUTO-GENERATED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";
import { ProfileNFT } from "../src/core/ProfileNFT.sol";
import { CyberEngine } from "../src/core/CyberEngine.sol";
import { PermissionedFeeCreationMw } from "../src/middlewares/profile/PermissionedFeeCreationMw.sol";

contract DeployScript is Script {
    struct DeployParameters {
        address link3Owner;
        address link3Signer;
        address engineAuthOwner;
        address engineGov;
    }

    DeployParameters internal deployParams;

    function _setDeployParams() private {
        if (block.chainid == 31337) {
            // use the same address that runs the deployment script
            deployParams.link3Owner = address(
                0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
            );
            deployParams.link3Signer = address(
                0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
            );
            deployParams.engineAuthOwner = address(
                0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
            );
            deployParams.engineGov = address(
                0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
            );
        }
    }

    function run() external {
        _setDeployParams();
        // TODO: this is Rinkeby address, change for prod
        address deployerContract;
        if (block.chainid == 31337) {
            // deployerContract = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
        } else if (block.chainid == 4) {
            deployerContract = 0x1202F1AAe12d3fcBFB9320eE2396c19f93581f41;
        } else if (block.chainid == 5) {
            // deployerContract = 0xdB94815F9D2f5A647c8D96124C7C1d1b42a23B47;
        }
        // require(deployerContract != address(0), "DEPLOYER_CONTRACT_NOT_SET");
        console.log("vm.getNonce", vm.getNonce(msg.sender));
        vm.startBroadcast();

        LibDeploy.deploy(
            vm,
            LibDeploy.DeployParams(
                true,
                deployerContract,
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
