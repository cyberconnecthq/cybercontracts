// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;
import "forge-std/Test.sol";

abstract contract TestIntegrationBase is Test {
    uint256 internal constant link3SignerPk = 1890;
    address internal immutable link3Signer;

    constructor() {
        link3Signer = vm.addr(link3SignerPk);
    }
}
