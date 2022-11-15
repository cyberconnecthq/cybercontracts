// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { IERC721 } from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

import { IProfileNFT } from "../interfaces/IProfileNFT.sol";

contract RelationshipChecker {
    address internal _namespace;

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address namespace) {
        _namespace = namespace;
    }

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Check if the profile issued EssenceNFT is collected by me.
     *
     * @param profileId The profile id.
     * @param essenceId The essence id.
     * @param me The address to check.
     */
    function isCollectedByMe(
        uint256 profileId,
        uint256 essenceId,
        address me
    ) external view returns (bool) {
        address essNFTAddr = IProfileNFT(_namespace).getEssenceNFT(
            profileId,
            essenceId
        );
        if (essNFTAddr == address(0)) {
            return false;
        }

        return IERC721(essNFTAddr).balanceOf(me) > 0;
    }

    /**
     * @notice Check if the profile is subscribed by me.
     *
     * @param profileId The profile id.
     * @param me The address to check.
     */
    function isSubscribedByMe(uint256 profileId, address me)
        external
        view
        returns (bool)
    {
        address subNFTAddr = IProfileNFT(_namespace).getSubscribeNFT(profileId);
        if (subNFTAddr == address(0)) {
            return false;
        }
        return IERC721(subNFTAddr).balanceOf(me) > 0;
    }
}
