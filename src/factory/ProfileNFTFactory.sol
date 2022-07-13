// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IProfileDeployer } from "../interfaces/IProfileDeployer.sol";
import { ProfileNFT } from "../core/ProfileNFT.sol";
import { DataTypes } from "../libraries/DataTypes.sol";

contract ProfileNFTFactory is IProfileDeployer {
    DataTypes.ProfileDeployParameters public override profileParams;

    function setProfileParameters(
        address engine,
        address subscribeBeacon,
        address essenceBeacon
    ) external override {
        profileParams.engine = engine;
        profileParams.essenceBeacon = essenceBeacon;
        profileParams.subBeacon = subscribeBeacon;
    }

    function deploy(bytes32 salt) external override returns (address addr) {
        addr = address(new ProfileNFT{ salt: salt }());
        delete profileParams;
    }
}
