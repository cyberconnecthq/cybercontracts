// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

abstract contract CyberBoxNFTStorage {
    // constant
    uint256 internal constant _VERSION = 1;
    string internal constant _VERSION_STR = "1";

    address public signer;
    address public owner;
}
