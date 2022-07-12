// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ProfileNFT } from "../../src/core/ProfileNFT.sol";
import { DataTypes } from "../../src/libraries/DataTypes.sol";
import { Actions } from "../../src/libraries/Actions.sol";
import { LibString } from "../../src/libraries/LibString.sol";
import { UpgradeableBeacon } from "../../src/upgradeability/UpgradeableBeacon.sol";

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

    // by pass sig check for testing
    function createProfile(DataTypes.CreateProfileParams calldata params)
        external
        returns (uint256)
    {
        uint256 id = _mint(params.to);
        Actions.createProfile(
            id,
            _totalCount,
            params,
            _profileById,
            _profileIdByHandleHash,
            _metadataById,
            _addressToPrimaryProfile
        );
        return id;
    }
}
