// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";

contract DeployScript is Script, DeploySetting {
    function run() external {
        _setDeployParams();

        vm.startBroadcast();

        if (
            block.chainid == DeploySetting.BNBT ||
            block.chainid == DeploySetting.GOERLI
        ) {
            LibDeploy.setProfileMw(
                vm,
                LibDeploy.DeployParams(true, true, deployParams),
                address(0xAF9104Eb9c6B21Efdc43BaaaeE70662d6CcE8798), //engineProxyAddress,
                address(0x57e12b7a5F38A7F9c23eBD0400e6E53F2a45F271), //address link3Profile,
                address(0) //address link3ProfileMw
            );
        } else if (
            block.chainid == DeploySetting.BNB ||
            block.chainid == DeploySetting.NOVA ||
            block.chainid == DeploySetting.POLYGON
        ) {
            LibDeploy.setProfileMw(
                vm,
                LibDeploy.DeployParams(true, true, deployParams),
                address(0x1cA51941a616D14C42D3e3B9E6E687d7F5054c3A), //engineProxyAddress,
                address(0x2723522702093601e6360CAe665518C4f63e9dA6), //address link3Profile,
                address(0xd37bbF27e39B2f8c4386BebcCdA0850EEfFD2a82) //address link3ProfileMw
            );
        } else {
            LibDeploy.setProfileMw(
                vm,
                LibDeploy.DeployParams(true, true, deployParams),
                address(0x346Bf45A74e1B9d31E0E5d747964f99c81FFFfD8), //engineProxyAddress,
                address(0xE2f8a9885E81429f1B464b01a1EA234293474945), //address link3Profile,
                address(0x338b17418da4887046FFBDaA52A6817E016911F5) //address link3ProfileMw
            );
        }

        vm.stopBroadcast();
    }
}
