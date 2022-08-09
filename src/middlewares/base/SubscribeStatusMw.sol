// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IProfileNFT } from "../../interfaces/IProfileNFT.sol";

import { ERC721 } from "../../dependencies/solmate/ERC721.sol";

library SubscribeStatusMw {
    /*//////////////////////////////////////////////////////////////
                            PUBLIC VIEW
    //////////////////////////////////////////////////////////////*/

    function checkSubscribe(uint256 profileId, address collector)
        internal
        view
        returns (bool)
    {
        address essenceOwnerSubscribeNFT = IProfileNFT(msg.sender)
            .getSubscribeNFT(profileId);
        if (
            essenceOwnerSubscribeNFT == address(0) ||
            ERC721(essenceOwnerSubscribeNFT).balanceOf(collector) == 0
        ) {
            return false;
        } else {
            return true;
        }
    }
}
