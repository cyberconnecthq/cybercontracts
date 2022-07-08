// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { Authority } from "../dependencies/solmate/Auth.sol";
import { RolesAuthority } from "../dependencies/solmate/RolesAuthority.sol";

import { CyberEngine } from "./CyberEngine.sol";

import { Constants } from "../libraries/Constants.sol";

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
            CyberEngine.setSigner.selector,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            CyberEngine.setProfileAddress.selector,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            CyberEngine.setFeeByTier.selector,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            CyberEngine.withdraw.selector,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            CyberEngine.setState.selector,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            CyberEngine.allowSubscribeMw.selector,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            CyberEngine.allowEssenceMw.selector,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            CyberEngine.upgradeProfile.selector,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            Constants._AUTHORIZE_UPGRADE,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            CyberEngine.setAnimationTemplate.selector,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            CyberEngine.setImageTemplate.selector,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            CyberEngine.pauseProfile.selector,
            true
        );
    }
}
