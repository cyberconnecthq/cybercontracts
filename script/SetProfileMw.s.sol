// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";

contract DeployScript is Script, DeploySetting {
    function run() external {
        _setDeployParams();

        vm.startBroadcast();

        if (block.chainid == DeploySetting.NOVA) {
            LibDeploy.setProfileMw(
                vm,
                LibDeploy.DeployParams(true, true, deployParams),
                address(0), //engineProxyAddress,
                address(0), //address link3Profile,
                address(0) //address link3ProfileMw
            );
        } else if (block.chainid == DeploySetting.BNBT) {
            LibDeploy.setProfileMw(
                vm,
                LibDeploy.DeployParams(true, true, deployParams),
                address(0x7294aB1F2C1601c3da46499574e16078a42c8056), //engineProxyAddress,
                address(0xc633795bE5E61F0363e239fC21cF32dbB073Fd21), //address link3Profile,
                address(0x342456d340D705f6B58137b57bEbEAd0069ba646) //address link3ProfileMw
            );
        } else if (block.chainid == DeploySetting.BNB) {
            LibDeploy.setProfileMw(
                vm,
                LibDeploy.DeployParams(true, true, deployParams),
                address(0x1cA51941a616D14C42D3e3B9E6E687d7F5054c3A), //engineProxyAddress,
                address(0x2723522702093601e6360CAe665518C4f63e9dA6), //address link3Profile,
                address(0xd37bbF27e39B2f8c4386BebcCdA0850EEfFD2a82) //address link3ProfileMw
            );
        }

        vm.stopBroadcast();
    }
}
