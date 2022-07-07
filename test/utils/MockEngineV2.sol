// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { CyberEngine } from "../../src/core/CyberEngine.sol";

contract MockEngineV2 is CyberEngine {
    function version() external pure override returns (uint256) {
        return 2;
    }
}
