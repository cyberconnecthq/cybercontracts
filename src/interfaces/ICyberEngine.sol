// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ICyberEngineEvents } from "../interfaces/ICyberEngineEvents.sol";

import { DataTypes } from "../libraries/DataTypes.sol";

interface ICyberEngine is ICyberEngineEvents {
    function getNameByNamespace(address namespace)
        external
        view
        returns (string memory);

    function getProfileMwByNamespace(address namespace)
        external
        view
        returns (address);

    function isEssenceMwAllowed(address mw) external view returns (bool);

    function isSubscribeMwAllowed(address mw) external view returns (bool);
}
