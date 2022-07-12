// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ICyberEngineEvents } from "../interfaces/ICyberEngineEvents.sol";

import { DataTypes } from "../libraries/DataTypes.sol";

interface ICyberEngine is ICyberEngineEvents {
    function getNamespaceData(address namespace)
        external
        view
        returns (DataTypes.NamespaceStruct memory);
}
