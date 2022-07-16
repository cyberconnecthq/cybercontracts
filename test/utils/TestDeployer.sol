// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ISubscribeDeployer } from "../../src/interfaces/ISubscribeDeployer.sol";
import { IEssenceDeployer } from "../../src/interfaces/IEssenceDeployer.sol";
import { IProfileDeployer } from "../../src/interfaces/IProfileDeployer.sol";

import { DataTypes } from "../../src/libraries/DataTypes.sol";

import { SubscribeNFT } from "../../src/core/SubscribeNFT.sol";
import { EssenceNFT } from "../../src/core/EssenceNFT.sol";
import { ProfileNFT } from "../../src/core/ProfileNFT.sol";

import { MockProfile } from "./MockProfile.sol";
import { TestProxy } from "./TestProxy.sol";

contract TestDeployer is
    IProfileDeployer,
    ISubscribeDeployer,
    IEssenceDeployer,
    TestProxy
{
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

    DataTypes.SubscribeDeployParameters public override subParams;

    function deploySubscribe(bytes32 salt, address profileProxy)
        public
        override
        returns (address addr)
    {
        subParams.profileProxy = profileProxy;
        addr = address(new SubscribeNFT{ salt: salt }());
        delete subParams;
    }

    DataTypes.EssenceDeployParameters public override essParams;

    function deployEssence(bytes32 salt, address profileProxy)
        public
        override
        returns (address addr)
    {
        essParams.profileProxy = profileProxy;
        addr = address(new EssenceNFT{ salt: salt }());
        delete essParams;
    }

    DataTypes.ProfileDeployParameters public override profileParams;

    function deployProfile(
        bytes32 salt,
        address engine,
        address subscribeBeacon,
        address essenceBeacon
    ) public override returns (address addr) {
        profileParams.engine = engine;
        profileParams.essenceBeacon = essenceBeacon;
        profileParams.subBeacon = subscribeBeacon;
        addr = address(new ProfileNFT{ salt: salt }());
        delete profileParams;
    }
}
