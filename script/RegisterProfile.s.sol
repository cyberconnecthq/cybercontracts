// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract DeployScript is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();

        LibDeploy.DeployParams memory params = LibDeploy.DeployParams(
            true,
            true,
            deployParams
        );

        if (block.chainid == 97) {
            LibDeploy.registerLink3TestProfile(
                vm,
                LibDeploy.RegisterLink3TestProfileParams(
                    address(0xc633795bE5E61F0363e239fC21cF32dbB073Fd21), // profile
                    address(0x7294aB1F2C1601c3da46499574e16078a42c8056), // engine
                    address(0x342456d340D705f6B58137b57bEbEAd0069ba646), // profile mw
                    address(0x927f355117721e0E8A7b5eA20002b65B8a551890), // toEOA
                    params.setting.link3Treasury,
                    params.setting.engineTreasury
                )
            );
        } else if (block.chainid == 5) {
            LibDeploy.registerLink3TestProfile(
                vm,
                LibDeploy.RegisterLink3TestProfileParams(
                    address(0x7B2bc3ae8f816a431Ff438d939C44E1A502EaD25),
                    address(0x47C282Bef1dE396Defd13878859B580636b81796),
                    address(0x8a07C56c28FC62CAC8F42fdD1F16f0cE3141c291),
                    address(0x927f355117721e0E8A7b5eA20002b65B8a551890),
                    params.setting.link3Treasury,
                    params.setting.engineTreasury
                )
            );
        }
        vm.stopBroadcast();
    }
}
