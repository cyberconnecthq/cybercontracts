// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface IProfileMiddleware {
    function setProfileMwData(address namespace, bytes calldata data)
        external
        returns (bytes memory);

    function preProcess(
        DataTypes.CreateProfileParams calldata params,
        bytes calldata data
    ) external payable;

    function postProcess(
        DataTypes.CreateProfileParams calldata params,
        bytes calldata data
    ) external;
}
