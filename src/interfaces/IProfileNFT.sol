// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface IProfileNFT {
    function createProfile(address to, DataTypes.ProfileStruct calldata vars)
        external
        returns (uint256);
}
