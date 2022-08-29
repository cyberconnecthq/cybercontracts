// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IProfileNFT } from "../../interfaces/IProfileNFT.sol";

import { ERC721 } from "../../dependencies/solmate/ERC721.sol";

/**
 * @title SubscribeOnceMw
 * @author CyberConnect
 * @notice This checks that the user can only have 0 subscribe NFTs before subscribing to the profile owner
 */
library SubscribeOnceMw {
    /*//////////////////////////////////////////////////////////////
                            PUBLIC VIEW
    //////////////////////////////////////////////////////////////*/

    function checkSubscribeOnce(uint256 profileId, address subscriber)
        internal
        view
        returns (bool)
    {
        address essenceOwnerSubscribeNFT = IProfileNFT(msg.sender)
            .getSubscribeNFT(profileId);

        return (ERC721(essenceOwnerSubscribeNFT).balanceOf(subscriber) == 0);
    }
}
