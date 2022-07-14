// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface ICyberEngineEvents {
    event AllowProfileMw(
        address indexed mw,
        bool indexed preAllowed,
        bool indexed newAllowed
    );

    event SetProfileMw(address indexed namespace, address mw, bytes returnData);

    /**
     * @notice Emitted when a subscription middleware has been allowed.
     *
     * @param mw The middleware address.
     * @param preAllowed The previously allow state.
     * @param newAllowed The newly set allow state.
     */
    event AllowSubscribeMw(
        address indexed mw,
        bool indexed preAllowed,
        bool indexed newAllowed
    );

    /**
     * @notice Emitted when a essence middleware has been allowed.
     *
     * @param mw The middleware address.
     * @param preAllowed The previously allow state.
     * @param newAllowed The newly set allow state.
     */
    event AllowEssenceMw(
        address indexed mw,
        bool indexed preAllowed,
        bool indexed newAllowed
    );
}
