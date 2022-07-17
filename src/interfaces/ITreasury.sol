// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface ITreasury {
    /**
     * @notice Gets the treasury address.
     *
     * @return address The treasury address.
     */
    function getTreasuryAddress() external view returns (address);

    /**
     * @notice Gets the treasury fee. The percentage is calculated as: treasuryFee/_MAX_BPS
     *
     * @return address The treasury fee.
     */
    function getTreasuryFee() external view returns (uint256);
}
