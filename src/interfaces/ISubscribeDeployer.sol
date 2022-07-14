// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface ISubscribeDeployer {
    function subParams() external view returns (address profileProxy);

    function deploySubscribe(bytes32 salt, address profileProxy)
        external
        returns (address addr);
}
