// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface ICyberEngineEvents {
    event AllowProfileMw(
        address indexed mw,
        bool indexed preAllowed,
        bool indexed newAllowed
    );

    event SetProfileMw(
        address indexed profileAddress,
        address mw,
        bytes returnData
    );
}
