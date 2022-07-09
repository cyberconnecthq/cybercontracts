// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ProfileNFT } from "../../src/core/ProfileNFT.sol";
import { DataTypes } from "../../src/libraries/DataTypes.sol";
import { LibString } from "../../src/libraries/LibString.sol";

contract MockProfile is ProfileNFT(address(0), address(0)) {
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

    function getSubscribeNFTTokenURI(uint256 profileId)
        external
        view
        override
        returns (string memory)
    {
        return LibString.toString(profileId);
    }
}
