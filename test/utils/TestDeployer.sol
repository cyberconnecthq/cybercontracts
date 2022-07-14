// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ProfileDeployer } from "../../src/deployer/ProfileDeployer.sol";
import { SubscribeDeployer } from "../../src/deployer/SubscribeDeployer.sol";
import { EssenceDeployer } from "../../src/deployer/EssenceDeployer.sol";
import { DataTypes } from "../../src/libraries/DataTypes.sol";
import { MockProfile } from "./MockProfile.sol";

contract TestDeployer is ProfileDeployer, SubscribeDeployer, EssenceDeployer {
    bytes32 internal _salt = keccak256(bytes("salt"));

    function deployMockProfile(
        address engine,
        address essenceBeacon,
        address subscribeBeacon
    ) internal returns (address addr) {
        profileParams.engine = engine;
        profileParams.essenceBeacon = essenceBeacon;
        profileParams.subBeacon = subscribeBeacon;
        addr = address(new MockProfile{ salt: _salt }());
        delete profileParams;
    }
}
