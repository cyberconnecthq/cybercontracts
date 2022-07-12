// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ITreasury } from "../../interfaces/ITreasury.sol";

abstract contract FeeMw {
    address public immutable TREASURY; // solhint-disable-line

    constructor(address treasury) {
        require(treasury != address(0), "ZERO_TREASURY_ADDRESS");
        TREASURY = treasury;
    }

    function _treasuryAddress() internal view returns (address) {
        return ITreasury(TREASURY).getTreasuryAddress();
    }

    function _treasuryFee() internal view returns (uint16) {
        return ITreasury(TREASURY).getTreasuryFee();
    }
}
