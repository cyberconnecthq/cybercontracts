// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface ITreasuryEvents {
    /**
     * @notice Emitted when a currency has been allowed.
     *
     * @param currency The ERC20 token contract address.
     * @param preAllowed The previously allow state.
     * @param newAllowed The newly set allow state.
     */
    event AllowCurrency(
        address indexed currency,
        bool indexed preAllowed,
        bool indexed newAllowed
    );
}
