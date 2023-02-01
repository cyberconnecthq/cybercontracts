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
                address(0xD08d211354D3fECbd453080d25d1a5234BCfe59B) //address stableFeeMw
            );
        } else if (block.chainid == DeploySetting.BNB) {
            LibDeploy.setStableFeeMw(
                vm,
                LibDeploy.DeployParams(true, true, deployParams),
                address(0x1cA51941a616D14C42D3e3B9E6E687d7F5054c3A), //engineProxyAddress,
                address(0x2723522702093601e6360CAe665518C4f63e9dA6), //address link3Profile,
                address(0) //address stableFeeMw
            );
        } else if (block.chainid == DeploySetting.BNBT) {
            LibDeploy.setStableFeeMw(
                vm,
                LibDeploy.DeployParams(true, true, deployParams),
                address(0xAF9104Eb9c6B21Efdc43BaaaeE70662d6CcE8798), //engineProxyAddress,
                address(0x57e12b7a5F38A7F9c23eBD0400e6E53F2a45F271), //address link3Profile,
                address(0) //address stableFeeMw
            );
        }

        vm.stopBroadcast();
    }
}
