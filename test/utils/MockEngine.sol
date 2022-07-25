// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { CyberEngine } from "../../src/core/CyberEngine.sol";

contract MockEngine is CyberEngine {
    function setNamespaceInfo(
        string calldata name,
        address profileMw,
        address namespace
    ) external {
        _namespaceInfo[namespace].name = name;
        _namespaceInfo[namespace].profileMw = profileMw;
    }
}
