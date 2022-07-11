// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface IProfileMiddleware {
    function preProcess(
        uint256 fee,
        DataTypes.CreateProfileParams calldata params
    ) external;

    function postProcess(
        uint256 fee,
        DataTypes.CreateProfileParams calldata params
    ) external;
}
