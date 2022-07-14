// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface IEssenceDeployer {
    function essParams() external view returns (address profileProxy);

    function deployEssence(bytes32 salt, address profileProxy)
        external
        returns (address addr);
}
