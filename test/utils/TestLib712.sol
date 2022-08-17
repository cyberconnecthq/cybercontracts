// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

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
        bytes32 ds = domainSeparator(name, version, addr);
        return keccak256(abi.encodePacked("\x19\x01", ds, structHash));
    }

    function domainSeparator(
        string memory name,
        string memory version,
        address addr
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _TYPE_HASH,
                    keccak256(bytes(name)),
                    keccak256(bytes(version)),
                    block.chainid,
                    addr
                )
            );
    }
}
