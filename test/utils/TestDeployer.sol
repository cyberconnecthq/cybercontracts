// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IProfileDeployer } from "../../src/interfaces/IProfileDeployer.sol";
import { DataTypes } from "../../src/libraries/DataTypes.sol";

contract TestDeployer is IProfileDeployer {
    DataTypes.DeployParameters public parameters;

    function setParamers(
        address _engine,
        address _profileProxy,
        address _subBeacon,
        address _essenceBeacon
    ) internal {
        parameters.engine = _engine;
        parameters.profileProxy = _profileProxy;
        parameters.subBeacon = _subBeacon;
        parameters.essenceBeacon = _essenceBeacon;
    }

    function setProfile(address _profile) internal {
        parameters.profileProxy = _profile;
    }
}
