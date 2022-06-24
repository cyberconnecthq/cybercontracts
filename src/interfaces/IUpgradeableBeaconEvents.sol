// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface IUpgradeableBeaconEvents {
	event Upgraded(address indexed implementation);    
}
