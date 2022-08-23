// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ERC721 } from "../../dependencies/solmate/ERC721.sol";

library NFTStatusMw {
    /*//////////////////////////////////////////////////////////////
                            PUBLIC VIEW
    //////////////////////////////////////////////////////////////*/

    function checkNFT(address nftAddress, address subscriber)
        internal
        view
        returns (bool)
    {
        return (ERC721(nftAddress).balanceOf(subscriber) != 0);
    }
}
