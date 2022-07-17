// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { CyberBoxNFT } from "../../src/periphery/CyberBoxNFT.sol";

contract MockCyberBoxV2 is CyberBoxNFT {
    function version() external pure override returns (uint256) {
        return 2;
    }
}
