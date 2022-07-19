// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { LibDeploy } from "../../libraries/LibDeploy.sol";
import { ProfileNFT } from "../../../src/core/ProfileNFT.sol";
import { CyberEngine } from "../../../src/core/CyberEngine.sol";
import { PermissionedFeeCreationMw } from "../../../src/middlewares/profile/PermissionedFeeCreationMw.sol";
import { DeploySetting } from "../.././libraries/DeploySetting.sol";
import { Create2Deployer } from "../../libraries/Create2Deployer.sol";

contract UpgradeScript is Script, DeploySetting {
    function run() external {
        _setDeployParams();

        console.log("vm.getNonce", vm.getNonce(msg.sender));
        vm.startBroadcast();

        deploy();

        vm.stopBroadcast();
    }

    function deploy() internal {
        Create2Deployer dc = Create2Deployer(deployParams.deployerContract);
        require(
            deployParams.deployerContract ==
                0xEFb8369Fb33bA67832B7120C94698e5372eE61C3
        );
        bytes32 SALT = keccak256(bytes("CyberConnect"));
        address engineProxy = address(
            0xE8805326f9DA84e70c680429eD46B924b3F158F2
        );
        address cyberTreasury = address(
            0x5DA0eD64A9868d128F8d6f56dC78B727F85ff2D0
        );
        address link3Profile = address(
            0x8CC6517e45dB7a0803feF220D9b577326A12033f
        );
        address profileMw = dc.deploy(
            abi.encodePacked(
                type(PermissionedFeeCreationMw).creationCode,
                abi.encode(engineProxy, cyberTreasury)
            ),
            SALT
        );
        console.log("=== new mw address ===");
        console.log(profileMw);
        CyberEngine(engineProxy).allowProfileMw(profileMw, true);

        // 8. Engine Config Link3 Profile Middleware
        CyberEngine(engineProxy).setProfileMw(
            link3Profile,
            profileMw,
            abi.encode(
                deployParams.link3Signer,
                deployParams.link3Treasury,
                LibDeploy._INITIAL_FEE_TIER0,
                LibDeploy._INITIAL_FEE_TIER1,
                LibDeploy._INITIAL_FEE_TIER2,
                LibDeploy._INITIAL_FEE_TIER3,
                LibDeploy._INITIAL_FEE_TIER4,
                LibDeploy._INITIAL_FEE_TIER5,
                LibDeploy._INITIAL_FEE_TIER6
            )
        );

        require(
            keccak256(bytes(ProfileNFT(link3Profile).name())) ==
                keccak256(bytes("Link3"))
        );
        require(
            PermissionedFeeCreationMw(profileMw).getSigner((link3Profile)) ==
                address(0x2A2EA826102c067ECE82Bc6E2B7cf38D7EbB1B82),
            "WRONG_SIGNER"
        );
        require(
            PermissionedFeeCreationMw(profileMw).getRecipient((link3Profile)) ==
                address(0xe75Fe33b0fB1441a11C5c1296e5Ca83B72cfE00d)
        );
        require(CyberEngine(engineProxy).isProfileMwAllowed(profileMw));
    }
}
