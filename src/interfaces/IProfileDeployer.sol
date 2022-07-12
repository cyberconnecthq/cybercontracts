// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IDeployer } from "../interfaces/IDeployer.sol";

interface IProfileDeployer is IDeployer {
    function parameters()
        external
        view
        returns (address subBeacon, address essenceBeacon);
}
