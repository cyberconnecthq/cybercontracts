// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/ProfileNFT.sol";
import "../src/libraries/Constants.sol";
import "../src/libraries/DataTypes.sol";
import "../src/base/RolesAuthority.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();

        RolesAuthority rolesAuthority;

        rolesAuthority = new RolesAuthority(
            address(this),
            Authority(address(0))
        );

        vm.stopBroadcast();
    }
}
