// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IProfileDeployer } from "../../src/interfaces/IProfileDeployer.sol";
import { ISubscribeDeployer } from "../../src/interfaces/ISubscribeDeployer.sol";
import { IEssenceDeployer } from "../../src/interfaces/IEssenceDeployer.sol";
import { DataTypes } from "../../src/libraries/DataTypes.sol";

contract TestDeployer is
    IProfileDeployer,
    ISubscribeDeployer,
    IEssenceDeployer
{
    DataTypes.EssenceDeployParameters public essParams;
    DataTypes.SubscribeDeployParameters public subParams;
    DataTypes.ProfileDeployParameters public profileParams;

    function setParamers(
        address _profileProxy,
        address _subBeacon,
        address _essenceBeacon,
        address _engine
    ) internal {
        essParams.profileProxy = _profileProxy;
        subParams.profileProxy = _profileProxy;
        profileParams.subBeacon = _subBeacon;
        profileParams.essenceBeacon = _essenceBeacon;
        profileParams.engine = _engine;
    }

    function setEssParameters(address profileProxy) external {}

    function setSubParameters(address profileProxy) external {}

    function setProfileParameters(
        address engine,
        address subscribeBeacon,
        address essenceBeacon
    ) external {}

    function setProfile(address _profile) internal {
        essParams.profileProxy = _profile;
        subParams.profileProxy = _profile;
    }

    function deploy(bytes32) external pure returns (address addr) {
        return address(0);
    }
}
