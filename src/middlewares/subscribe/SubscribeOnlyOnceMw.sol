// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { ISubscribeMiddleware } from "../../interfaces/ISubscribeMiddleware.sol";
import { ERC721 } from "../../dependencies/solmate/ERC721.sol";

/**
 * @title Subscribe Only Once Middleware
 * @author CyberConnect
 * @notice This contract is a middleware to allow the address to subscribe only once to another address.
 */
contract SubscribeOnlyOnceMw is ISubscribeMiddleware {
    /**
     * @inheritdoc ISubscribeMiddleware
     * @notice Proccess that checks if the subscriber is aready subscribed.
     */
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

    /// @inheritdoc ISubscribeMiddleware
    function postProcess(
        uint256 profileId,
        address subscriber,
        address subscrbeNFT,
        bytes calldata data
    ) external {
        // do nothing
    }
}
