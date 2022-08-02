// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IProfileNFT } from "../../interfaces/IProfileNFT.sol";

import { ERC721 } from "../../dependencies/solmate/ERC721.sol";

library SubscribeStatusMw {
    /*//////////////////////////////////////////////////////////////
                            PUBLIC VIEW
    //////////////////////////////////////////////////////////////*/

    function checkSubscribe(uint256 profileId, address collector) public view {
        address essenceOwnerSubscribeNFT = IProfileNFT(msg.sender)
            .getSubscribeNFT(profileId);

        require(essenceOwnerSubscribeNFT != address(0), "NO_SUBSCRIBE_NFT");

        require(
            ERC721(essenceOwnerSubscribeNFT).balanceOf(collector) != 0,
            "NOT_SUBSCRIBED"
        );
    }
}
