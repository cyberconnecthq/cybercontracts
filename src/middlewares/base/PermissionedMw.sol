// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ICyberEngine } from "../../interfaces/ICyberEngine.sol";

abstract contract PermissionedMw {
    address public immutable ENGINE;

    modifier onlyNamespaceOwner(address profileAddress) {
        string memory namespace = ICyberEngine(ENGINE)
            .getNamespaceByProfileAddr(profileAddress);
        require(namespace.owner == msg.sender, "NON_NAMESPACE_OWNER");
        _;
    }

    constructor(address engine) {
        require(engine != address(0), "ENGINE_ADDRESS_ZERO");
        ENGINE = engine;
    }
}
