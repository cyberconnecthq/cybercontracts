// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ProfileNFT } from "../../src/core/ProfileNFT.sol";
import { DataTypes } from "../../src/libraries/DataTypes.sol";

contract MockProfileBypassSig is ProfileNFT(address(0), address(0)) {
    // by pass sig check for testing
    function createProfile(DataTypes.CreateProfileParams calldata params)
        external
        returns (uint256)
    {
        return _createProfile(params);
    }
}
