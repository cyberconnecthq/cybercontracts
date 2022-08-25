// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../../src/libraries/DataTypes.sol";

import { ProfileNFT } from "../../src/core/ProfileNFT.sol";

contract MockProfile is ProfileNFT {
    // set internal states for testing
    function setSubscribeNFTAddress(uint256 profileId, address subscribeAddr)
        external
    {
        _subscribeByProfileId[profileId].subscribeNFT = subscribeAddr;
    }

    // set internal states for testing
    function setEssenceNFTAddress(
        uint256 profileId,
        uint256 essenceId,
        address essenceAddr
    ) external {
        _essenceByIdByProfileId[profileId][essenceId].essenceNFT = essenceAddr;
    }
}
