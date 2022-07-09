// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { SubscribeNFT } from "../../src/core/SubscribeNFT.sol";

contract MockSubscribeNFTV2 is SubscribeNFT {
    constructor(address profileNFT) SubscribeNFT(profileNFT) {}

    function version() external pure override returns (uint256) {
        return 2;
    }
}
