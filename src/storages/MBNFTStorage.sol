// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

abstract contract MBNFTStorage {
    // constant
    uint256 internal constant _VERSION = 1;

    // storage
    string internal _tokenURI;
    address internal _boxAddr;
}
