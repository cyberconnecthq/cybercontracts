// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;
import "forge-std/Test.sol";

import { ProfileNFT } from "../../src/core/ProfileNFT.sol";
import { CyberEngine } from "../../src/core/CyberEngine.sol";
import { Link3ProfileDescriptor } from "../../src/periphery/Link3ProfileDescriptor.sol";
import { PermissionedFeeCreationMw } from "../../src/middlewares/profile/PermissionedFeeCreationMw.sol";
import { LibDeploy } from "../../script/libraries/LibDeploy.sol";

abstract contract TestIntegrationBase is Test {
    uint256 internal constant link3SignerPk = 1890;
    address internal immutable link3Signer;
    address internal constant alice = address(0xDEADA11CE);
    address internal constant bob = address(0xDEADB0B);

    ProfileNFT profile;
    Link3ProfileDescriptor profileDescriptor;
    PermissionedFeeCreationMw profileMw;
    CyberEngine engine;

    constructor() {
        link3Signer = vm.addr(link3SignerPk);
    }

    function _setUp() internal {
        LibDeploy.ContractAddresses memory addrs = LibDeploy.deployInTest(
            vm,
            link3Signer
        );
        profile = ProfileNFT(addrs.link3Profile);
        profileDescriptor = Link3ProfileDescriptor(addrs.link3DescriptorProxy);
        profileMw = PermissionedFeeCreationMw(addrs.link3ProfileMw);
        engine = CyberEngine(addrs.engineProxyAddress);
    }
}
