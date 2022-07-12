// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IProfileDeployer } from "../interfaces/IProfileDeployer.sol";
import { ProfileNFT } from "../core/ProfileNFT.sol";
import { DataTypes } from "../libraries/DataTypes.sol";

contract ProfileNFTFactory is IProfileDeployer {
    DataTypes.ProfileDeployParameters public override parameters;

    constructor(
        address subscribeBeacon,
        address essenceBeacon,
        bytes32 salt
    ) {
        parameters.essenceBeacon = essenceBeacon;
        parameters.subBeacon = subscribeBeacon;
    }

    function deploy(bytes32 salt) external override {
        new ProfileNFT{ salt: salt }();
    }
}
