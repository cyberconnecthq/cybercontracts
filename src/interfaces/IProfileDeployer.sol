// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IDeployer } from "../interfaces/IDeployer.sol";

interface IProfileDeployer is IDeployer {
    function profileParams()
        external
        view
        returns (
            address engine,
            address subBeacon,
            address essenceBeacon
        );

    function setProfileParameters(
        address engine,
        address subscribeBeacon,
        address essenceBeacon
    ) external;
}
