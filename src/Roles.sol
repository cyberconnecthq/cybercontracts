// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { Authority } from "../src/dependencies/solmate/Auth.sol";
import { RolesAuthority } from "../src/dependencies/solmate/RolesAuthority.sol";
import { Constants } from "../src/libraries/Constants.sol";
import { CyberEngine } from "../src/CyberEngine.sol";

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
            CyberEngine.setBoxAddress.selector,
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
            CyberEngine.setBoxGiveawayEnded.selector,
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
            CyberEngine.upgradeProfile.selector,
            true
        );
        setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            CyberEngine.upgradeBox.selector,
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
    }
}
