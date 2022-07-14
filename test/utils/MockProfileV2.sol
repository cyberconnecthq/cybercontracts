// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ProfileNFT } from "../../src/core/ProfileNFT.sol";

contract MockProfileV2 is ProfileNFT {
    function version() external pure override returns (uint256) {
        return 2;
    }
}
