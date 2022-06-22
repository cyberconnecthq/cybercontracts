// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { CyberEngine } from "../../src/CyberEngine.sol";
import { DataTypes } from "../../src/libraries/DataTypes.sol";

contract MockEngine is CyberEngine {
    function verifySignature(
        bytes32 digest,
        DataTypes.EIP712Signature calldata sig
    ) public view {
        super._verifySignature(digest, sig);
    }

    function requireEnoughFee(string calldata handle, uint256 amount)
        public
        view
    {
        super._requireEnoughFee(handle, amount);
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
}
