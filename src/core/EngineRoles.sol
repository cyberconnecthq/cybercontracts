// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { Authority } from "../dependencies/solmate/Auth.sol";
import { RolesAuthority } from "../dependencies/solmate/RolesAuthority.sol";
import { Constants } from "../libraries/Constants.sol";
import { CyberEngine } from "./CyberEngine.sol";

/**
 * @title Roles
 * @author CyberConnect
 * @notice This contract is used to set roles.
 */
contract Roles is RolesAuthority {
    constructor(address owner, address engine)
        RolesAuthority(owner, Authority(address(0)))
    {
        _initSetup(engine);
    }

    /**
     * @notice Initializes the roles.
     *
     * @param engine The engine address
     */
    function _initSetup(address engine) internal {
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            CyberEngine.allowProfileMw.selector,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            CyberEngine.createNamespace.selector,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            CyberEngine.setProfileMw.selector,
            true
        );
    }
}
