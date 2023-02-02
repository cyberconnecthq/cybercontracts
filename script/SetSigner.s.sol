// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { ProfileNFT } from "../src/core/ProfileNFT.sol";
import { CyberEngine } from "../src/core/CyberEngine.sol";
import { Link3ProfileDescriptor } from "../src/periphery/Link3ProfileDescriptor.sol";
import { RolesAuthority } from "../src/dependencies/solmate/RolesAuthority.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";
import { PermissionedFeeCreationMw } from "../src/middlewares/profile/PermissionedFeeCreationMw.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();
        // address link3Desc = 0x3B131D2d6694a60eb71dfF607cc64E6296daa71E;
        // address preOwner = 0x39e0c6E610A8D7F408dD688011591583cbc1c3ce;
        // address newOwner = 0xf9E12df9428F1a15BC6CfD4092ADdD683738cE96;

        // require(Link3ProfileDescriptor(link3Desc).owner() == preOwner, "WRONG_OWNER");
        // Link3ProfileDescriptor(link3Desc).setOwner(newOwner);
        // require(Link3ProfileDescriptor(link3Desc).owner() == newOwner, "WRONG_NEW_OWNER");

        // address roleAuth = 0x9937fb8ebe4Ebc7710fFAEd246584603F390BE3E;
        // address preOwner = 0xA7b6bEf855c1c57Df5b7C9c7a4e1eB757e544e7f;
        // address newOwner = 0xf9E12df9428F1a15BC6CfD4092ADdD683738cE96;

        // require(RolesAuthority(roleAuth).owner() == preOwner, "WRONG_OWNER");
        // RolesAuthority(roleAuth).setOwner(newOwner);
        // require(
        //     RolesAuthority(roleAuth).owner() == newOwner,
        //     "WRONG_NEW_OWNER"
        // );

        address link3Profile = 0x2723522702093601e6360CAe665518C4f63e9dA6;
        address preOwner = 0x39e0c6E610A8D7F408dD688011591583cbc1c3ce;
        address newOwner = 0xf9E12df9428F1a15BC6CfD4092ADdD683738cE96;

        require(
            ProfileNFT(link3Profile).getNamespaceOwner() == preOwner,
            "WRONG_NS_OWNER"
        );
        ProfileNFT(link3Profile).setNamespaceOwner(newOwner);
        require(
            ProfileNFT(link3Profile).getNamespaceOwner() == newOwner,
            "WRONG_NEW_OWNER"
        );

        vm.stopBroadcast();
    }
}
