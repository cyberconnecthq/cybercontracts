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
        (profileAddr, , ) = LibDeploy.createNamespace(
            address(0x47C282Bef1dE396Defd13878859B580636b81796), // engine proxy address
            address(0x927f355117721e0E8A7b5eA20002b65B8a551890), // link3Owner
            CYBERCONNECT_NAME, // LINK3_NAME,
            CYBERCONNECT_SYMBOL, // LINK3_SYMBOL,
            CYBERCONNECT_SALT, // LINK3_SALT,
            address(0x7b814e59Cf6a4f07aad8390321fdC3c44d7Da2FC), // addrs.profileFac,
            address(0x92F560234c234267Dfe73af20D3Fa6c9C9E92A45), // addrs.subFac,
            address(0xd0579ba5ad373840d0b976802A5B075fC4B6Fd16) // addrs.essFac
        );
        vm.stopBroadcast();
    }
}
