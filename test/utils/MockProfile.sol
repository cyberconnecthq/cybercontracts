// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ProfileNFT } from "../../src/core/ProfileNFT.sol";
import { DataTypes } from "../../src/libraries/DataTypes.sol";
import { LibString } from "../../src/libraries/LibString.sol";
import { UpgradeableBeacon } from "../../src/upgradeability/UpgradeableBeacon.sol";

contract MockProfile is ProfileNFT {
    constructor(address _subBeacon, address _essenceBeacon)
        ProfileNFT(_subBeacon, _essenceBeacon)
    {}

    function verifySignature(
        bytes32 digest,
        DataTypes.EIP712Signature calldata sig
    ) public view {
        _requiresExpectedSigner(digest, signer, sig);
    }

    function requireEnoughFee(string calldata handle, uint256 amount)
        public
        view
    {
        _requiresEnoughFee(handle, amount);
    }

    // Expose for test
    function hashTypedDataV4(bytes32 structHash)
        public
        view
        virtual
        returns (bytes32)
    {
        return super._hashTypedDataV4(structHash);
    }

    // for testing
    function setSubscribeNFTAddress(uint256 profileId, address subscribeAddr)
        external
    {
        _subscribeByProfileId[profileId].subscribeNFT = subscribeAddr;
    }

    // by pass sig check for testing
    function createProfile(DataTypes.CreateProfileParams calldata params)
        external
        returns (uint256)
    {
        return _createProfile(params);
    }
}
