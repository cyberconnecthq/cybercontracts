// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { ECDSA } from "../../src/dependencies/openzeppelin/ECDSA.sol";

library TestLib712 {
    bytes32 private constant _TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    // Util function
    function hashTypedDataV4(
        address addr,
        bytes32 structHash,
        string memory name,
        string memory version
    ) internal view returns (bytes32) {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                _TYPE_HASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                block.chainid,
                addr
            )
        );
        return ECDSA.toTypedDataHash(domainSeparator, structHash);
    }
}
