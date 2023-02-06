// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";

contract DeployScript is Script, DeploySetting {
    function run() external {
        _setDeployParams();

        vm.startBroadcast();

        if (block.chainid == DeploySetting.GOERLI) {
            LibDeploy.setStableFeeMw(
                vm,
                LibDeploy.DeployParams(true, true, deployParams),
                address(0xAF9104Eb9c6B21Efdc43BaaaeE70662d6CcE8798), //engineProxyAddress,
                address(0x57e12b7a5F38A7F9c23eBD0400e6E53F2a45F271), //address link3Profile,
                address(0x940d11e9105d7C0FFEE91E5e6B2375E3A58ec18A) //address stableFeeMw
            );
        } else if (block.chainid == DeploySetting.BNB) {
            LibDeploy.setStableFeeMw(
                vm,
                LibDeploy.DeployParams(true, true, deployParams),
                address(0x1cA51941a616D14C42D3e3B9E6E687d7F5054c3A), //engineProxyAddress,
                address(0x2723522702093601e6360CAe665518C4f63e9dA6), //address link3Profile,
                address(0xAd246cc868A43c9dbE39Ca814860B88714E20822) //address stableFeeMw
            );
        } else if (block.chainid == DeploySetting.BNBT) {
            LibDeploy.setStableFeeMw(
                vm,
                LibDeploy.DeployParams(true, true, deployParams),
                address(0xAF9104Eb9c6B21Efdc43BaaaeE70662d6CcE8798), //engineProxyAddress,
                address(0x57e12b7a5F38A7F9c23eBD0400e6E53F2a45F271), //address link3Profile,
                address(0) //address stableFeeMw
            );
        } else if (block.chainid == DeploySetting.MAINNET) {
            LibDeploy.setStableFeeMw(
                vm,
                LibDeploy.DeployParams(true, true, deployParams),
                address(0xE8805326f9DA84e70c680429eD46B924b3F158F2), //engineProxyAddress,
                address(0x8CC6517e45dB7a0803feF220D9b577326A12033f), //address link3Profile,
                address(0x4C4bfA07bd28D1817D90E63a088643956f248159) //address stableFeeMw
            );
        } else if (block.chainid == DeploySetting.POLYGON) {
            LibDeploy.setStableFeeMw(
                vm,
                LibDeploy.DeployParams(true, true, deployParams),
                address(0x64E1503a2419966c51332d7f6018dE9544AD78a1), //engineProxyAddress,
                address(0xbF029d040e3E6DA7b768b759dD9D67D84c73C06f), //address link3Profile,
                address(0x45C3D3dC105Ba805E610f7fc2F3b4Ca5E29097a7) //address stableFeeMw
            );
        }

        vm.stopBroadcast();
    }
}
