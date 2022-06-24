// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { ISubscribeMiddleware } from "../../interfaces/ISubscribeMiddleware.sol";
import { ERC721 } from "../../dependencies/solmate/ERC721.sol";

contract SubscribeOnlyOnceMw is ISubscribeMiddleware {
    function preProcess(
        uint256 profileId,
        address subscriber,
        address subscrbeNFT,
        bytes calldata data
    ) external {
        require(
            ERC721(subscrbeNFT).balanceOf(subscriber) == 0,
            "Already subscribed"
        );
    }

    function postProcess(
        uint256 profileId,
        address subscriber,
        address subscrbeNFT,
        bytes calldata data
    ) external {
        // do nothing
    }
}
