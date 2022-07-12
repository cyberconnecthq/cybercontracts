// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface ITreasury {
    function getTreasuryAddress() external view returns (address);

    function getTreasuryFee() external view returns (uint16);
}
