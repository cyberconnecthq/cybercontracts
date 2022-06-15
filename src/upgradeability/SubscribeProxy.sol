// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";
import {ERC1967Upgrade} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";

// Adapted from OZ's beacon proxy for upgradeability and better etherscan support for EIP1967
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/109778c17c7020618ea4e035efb9f0f9b82d43ca/contracts/proxy/beacon/BeaconProxy.sol
contract SubscribeProxy is Proxy, ERC1967Upgrade {

}