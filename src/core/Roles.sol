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
            Constants._PROFILE_GOV_ROLE,
            engine,
            ProfileNFT.setSigner.selector,
            true
        );
        setRoleCapability(
            Constants._PROFILE_GOV_ROLE,
            engine,
            ProfileNFT.setFeeByTier.selector,
            true
        );
        setRoleCapability(
            Constants._PROFILE_GOV_ROLE,
            engine,
            ProfileNFT.withdraw.selector,
            true
        );

        setRoleCapability(
            Constants._PROFILE_GOV_ROLE,
            engine,
            ProfileNFT.allowSubscribeMw.selector,
            true
        );
        setRoleCapability(
            Constants._PROFILE_GOV_ROLE,
            engine,
            ProfileNFT.allowEssenceMw.selector,
            true
        );
        setRoleCapability(
            Constants._PROFILE_GOV_ROLE,
            engine,
            Constants._AUTHORIZE_UPGRADE,
            true
        );
        setRoleCapability(
            Constants._PROFILE_GOV_ROLE,
            engine,
            ProfileNFT.setAnimationTemplate.selector,
            true
        );
        setRoleCapability(
            Constants._PROFILE_GOV_ROLE,
            engine,
            ProfileNFT.setProfileNFTDescriptor.selector,
            true
        );
        setRoleCapability(
            Constants._PROFILE_GOV_ROLE,
            engine,
            ProfileNFT.pause.selector,
            true
        );
    }
}
