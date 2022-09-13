// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { DeploySetting } from "./libraries/DeploySetting.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";

contract DeployScript is Script, DeploySetting {
    string internal constant CYBERCONNECT_NAME = "CyberConnect";
    string internal constant CYBERCONNECT_SYMBOL = "CYBERCONNECT";
    bytes32 constant CYBERCONNECT_SALT = keccak256(bytes(CYBERCONNECT_NAME));

    function run() external {
        _setDeployParams();
        vm.startBroadcast();
        address profileAddr;
        if (block.chainid == 97 || block.chainid == 5) {
            (profileAddr, , ) = LibDeploy.createNamespace(
                address(0xAF9104Eb9c6B21Efdc43BaaaeE70662d6CcE8798), // engine proxy address
                address(0x927f355117721e0E8A7b5eA20002b65B8a551890), // link3Owner
                CYBERCONNECT_NAME, // LINK3_NAME,
                CYBERCONNECT_SYMBOL, // LINK3_SYMBOL,
                CYBERCONNECT_SALT, // LINK3_SALT,
                address(0x27361075Ea6E85564a4B00F5828235FC4C8C2e32), // addrs.profileFac,
                address(0x958d142Ef3a7B2ee34CDF1F81C135FB91a454A5C), // addrs.subFac,
                address(0x216BA81b5FD81253FDE6888039c6001D6f891eFb) // addrs.essFac
            );
        }

        console.log("CyberConnect Profile:", profileAddr);
        vm.stopBroadcast();
    }
}
