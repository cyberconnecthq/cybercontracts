// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ISubscribeDeployer } from "../interfaces/ISubscribeDeployer.sol";
import { SubscribeNFT } from "../core/SubscribeNFT.sol";
import { DataTypes } from "../libraries/DataTypes.sol";

contract SubscribeNFTFactory is ISubscribeDeployer {
    DataTypes.SubscribeDeployParameters public override subParams;

    function setSubParameters(address profileProxy) external override {
        subParams.profileProxy = profileProxy;
    }

    function deploy(bytes32 salt) external override returns (address addr) {
        addr = address(new SubscribeNFT{ salt: salt }());
        delete subParams;
    }
}
