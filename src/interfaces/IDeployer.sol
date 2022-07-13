// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface IDeployer {
    function deploy(bytes32 salt) external returns (address addr);
}
