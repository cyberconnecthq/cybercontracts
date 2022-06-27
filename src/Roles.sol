// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { Authority } from "../src/dependencies/solmate/Auth.sol";
import { RolesAuthority } from "../src/dependencies/solmate/RolesAuthority.sol";
import { Constants } from "../src/libraries/Constants.sol";

contract Roles is RolesAuthority {
    constructor(address owner, address engine)
        RolesAuthority(owner, Authority(address(0)))
    {
        _initSetup(engine);
    }

    function _initSetup(address engine) internal {
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            Constants._SET_SIGNER,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            Constants._SET_PROFILE_ADDR,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            Constants._SET_BOX_ADDR,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            Constants._SET_FEE_BY_TIER,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            Constants._WITHDRAW,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            Constants._SET_BOX_OPENED,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            Constants._SET_STATE,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            Constants._ALLOW_SUBSCRIBE_MW,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            Constants._UPGRADE_PROFILE,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            Constants._UPGRADE_BOX,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            Constants._AUTHORIZE_UPGRADE,
            true
        );
    }
}
