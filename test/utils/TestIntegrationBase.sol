// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";

import { ProfileNFT } from "../../src/core/ProfileNFT.sol";
import { CyberEngine } from "../../src/core/CyberEngine.sol";
import { Link3ProfileDescriptor } from "../../src/periphery/Link3ProfileDescriptor.sol";
import { PermissionedFeeCreationMw } from "../../src/middlewares/profile/PermissionedFeeCreationMw.sol";
import { CollectOnlySubscribedMw } from "../../src/middlewares/essence/CollectOnlySubscribedMw.sol";

import { LibDeploy } from "../../script/libraries/LibDeploy.sol";

import { TestProxy } from "./TestProxy.sol";

abstract contract TestIntegrationBase is Test, TestProxy {
    uint256 internal constant link3SignerPk = 1890;
    address internal immutable link3Signer = vm.addr(link3SignerPk);
    address internal constant alice = address(0xDEADA11CE);
    uint256 internal constant bobPk = 548;
    address internal immutable bob = vm.addr(bobPk);
    address internal constant carly = address(0xDEADCA11);
    address internal constant dixon = address(0xDEADD1);

    address internal constant link3Treasury = address(0xDEAD3333);
    address internal constant engineTreasury = address(0xDEADEEEE);
    address link3EssBeacon;

    ProfileNFT link3Profile;
    Link3ProfileDescriptor profileDescriptor;
    PermissionedFeeCreationMw profileMw;
    CollectOnlySubscribedMw collectMw;
    CyberEngine engine;

    LibDeploy.ContractAddresses addrs;

    function _setUp() internal {
        addrs = LibDeploy.deployInTest(
            vm,
            link3Signer,
            link3Treasury,
            engineTreasury
        );
        link3Profile = ProfileNFT(addrs.link3Profile);
        profileDescriptor = Link3ProfileDescriptor(addrs.link3DescriptorProxy);
        profileMw = PermissionedFeeCreationMw(addrs.link3ProfileMw);
        engine = CyberEngine(addrs.engineProxyAddress);
        link3EssBeacon = addrs.essBeacon;
    }
}
