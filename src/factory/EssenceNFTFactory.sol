// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IEssenceDeployer } from "../interfaces/IEssenceDeployer.sol";
import { EssenceNFT } from "../core/EssenceNFT.sol";
import { DataTypes } from "../libraries/DataTypes.sol";

contract EssenceNFTFactory is IEssenceDeployer {
    DataTypes.EssenceDeployParameters public override essParams;

    // TODO: access
    function setEssParameters(address profileProxy) external override {
        essParams.profileProxy = profileProxy;
    }

    // TODO:
    function deploy(bytes32 salt) external override returns (address addr) {
        addr = address(new EssenceNFT{ salt: salt }());
        delete essParams;
    }
}
