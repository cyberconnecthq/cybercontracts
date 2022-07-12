// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface IProfileDeployer {
    function parameters()
        external
        view
        returns (
            address engine,
            address profileProxy,
            address subBeacon,
            address essenceBeacon
        );
}
