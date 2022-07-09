// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

abstract contract CyberEngineStorage {
    // constant
    string internal constant _VERSION_STRING = "1"; // for 712, should never  change
    uint256 internal constant _VERSION = 1;

    // storage
    address public profileAddress;
    mapping(address => bool) internal _profileMwAllowlist;
    mapping(address => DataTypes.NamespaceStruct)
        internal _namespaceByProfileAddr;
}
