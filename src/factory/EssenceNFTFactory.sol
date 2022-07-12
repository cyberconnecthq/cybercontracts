// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IEssenceDeployer } from "../interfaces/IEssenceDeployer.sol";
import { EssenceNFT } from "../core/EssenceNFT.sol";
import { DataTypes } from "../libraries/DataTypes.sol";

contract EssenceNFTFactory is IEssenceDeployer {
    DataTypes.EssenceDeployParameters public override parameters;

    constructor(address profileProxy, bytes32 salt) {
        parameters.profileProxy = profileProxy;
    }

    function deploy(bytes32 salt) external override {
        new EssenceNFT{ salt: salt }();
    }
}
