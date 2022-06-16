// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { SubscribeNFT } from "../../src/SubscribeNFT.sol";

contract MockSubscribeNFTV2 is SubscribeNFT {
    constructor(address engine, address profileNFT)
        SubscribeNFT(engine, profileNFT)
    {}

    function version() external pure override returns (uint256) {
        return 2;
    }
}
