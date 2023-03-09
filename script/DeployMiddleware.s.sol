// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract DeployScript is Script, DeploySetting {
    function run() external {
        _setDeployParams();
        vm.startBroadcast();
        if (block.chainid == DeploySetting.BNBT) {
            LibDeploy.deployAllMiddleware(
                vm,
                LibDeploy.DeployParams(true, true, deployParams),
                address(0xAF9104Eb9c6B21Efdc43BaaaeE70662d6CcE8798), // engine proxy address
                address(0x3963744012daDf90A9034Ea1068f53108B1A3834), // cyber treasury address
                address(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e), // bnb-usd oracle address
                address(0x57e12b7a5F38A7F9c23eBD0400e6E53F2a45F271), // namespace
                true
            );
        } else if (block.chainid == DeploySetting.BNB) {
            LibDeploy.deployAllMiddleware(
                vm,
                LibDeploy.DeployParams(true, true, deployParams),
                address(0x1cA51941a616D14C42D3e3B9E6E687d7F5054c3A), // engine proxy address
                address(0x90137F1234C137C4284dd317303F2717c871f70A), // cyber treasury address
                address(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE), // bnb-usd oracle address
                address(0x2723522702093601e6360CAe665518C4f63e9dA6), // namespace
                true
            );
        }
        vm.stopBroadcast();
    }
}
