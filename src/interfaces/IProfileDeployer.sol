// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface IProfileDeployer {
    function profileParams()
        external
        view
        returns (
            address engine,
            address subBeacon,
            address essenceBeacon
        );

    function deployProfile(
        bytes32 salt,
        address engine,
        address subscribeBeacon,
        address essenceBeacon
    ) external returns (address addr);
}
