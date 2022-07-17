// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import { Pausable } from "../../src/dependencies/openzeppelin/Pausable.sol";

contract MockPausable is Pausable {
    bool public drasticMeasureTaken;
    uint256 public count;

    constructor() {
        drasticMeasureTaken = false;
        count = 0;
    }

    function normalProcess() external whenNotPaused {
        count++;
    }

    function drasticMeasure() external whenPaused {
        drasticMeasureTaken = true;
    }

    function pause() external {
        _pause();
    }

    function unpause() external {
        _unpause();
    }
}
