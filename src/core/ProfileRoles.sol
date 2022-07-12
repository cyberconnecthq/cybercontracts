// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { Authority } from "../dependencies/solmate/Auth.sol";
import { RolesAuthority } from "../dependencies/solmate/RolesAuthority.sol";
import { Constants } from "../libraries/Constants.sol";
import { ProfileNFT } from "./ProfileNFT.sol";

/**
 * @title Roles
 * @author CyberConnect
 * @notice This contract is used to set roles.
 */
contract ProfileRoles is RolesAuthority {
    constructor(address owner, address profile)
        RolesAuthority(owner, Authority(address(0)))
    {
        _initSetup(profile);
    }

    /**
     * @notice Initializes the roles.
     *
     * @param profile The profile address
     */
    function _initSetup(address profile) internal {
        setRoleCapability(
            Constants._PROFILE_GOV_ROLE,
            profile,
            ProfileNFT.allowSubscribeMw.selector,
            true
        );
        setRoleCapability(
            Constants._PROFILE_GOV_ROLE,
            profile,
            ProfileNFT.allowEssenceMw.selector,
            true
        );
        setRoleCapability(
            Constants._PROFILE_GOV_ROLE,
            profile,
            Constants._AUTHORIZE_UPGRADE,
            true
        );
        setRoleCapability(
            Constants._PROFILE_GOV_ROLE,
            profile,
            ProfileNFT.setAnimationTemplate.selector,
            true
        );
        setRoleCapability(
            Constants._PROFILE_GOV_ROLE,
            profile,
            ProfileNFT.setLink3ProfileDescriptor.selector,
            true
        );
        setRoleCapability(
            Constants._PROFILE_GOV_ROLE,
            profile,
            ProfileNFT.pause.selector,
            true
        );
    }
}
