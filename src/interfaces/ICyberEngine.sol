// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";
import { ICyberEngineEvents } from "../interfaces/ICyberEngineEvents.sol";

interface ICyberEngine is ICyberEngineEvents {
    function getNamespaceData(address namespace)
        external
        view
        returns (DataTypes.NamespaceStruct memory);
}
