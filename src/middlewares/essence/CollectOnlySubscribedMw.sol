// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ERC721 } from "../../dependencies/solmate/ERC721.sol";

import { IEssenceMiddleware } from "../../interfaces/IEssenceMiddleware.sol";
import { IProfileNFT } from "../../interfaces/IProfileNFT.sol";

import { SubscribeStatusMw } from "../base/SubscribeStatusMw.sol";

/**
 * @title Collect only when subscribed Middleware
 * @author CyberConnect
 * @notice This contract is a middleware to allow the address to collect an essence only if they are subscribed
 */
contract CollectOnlySubscribedMw is IEssenceMiddleware {
    /*//////////////////////////////////////////////////////////////
                         EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEssenceMiddleware
    function setEssenceMwData(
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes memory) {
        // do nothing
        return new bytes(0);
    }

    /**
     * @inheritdoc IEssenceMiddleware
     * @notice Proccess that checks if the user is aready subscribed to the essence owner
     */
    function preProcess(
        uint256 profileId,
        uint256,
        address collector,
        address,
        bytes calldata
    ) external view override {
        SubscribeStatusMw.checkSubscribe(profileId, collector);
    }

    /// @inheritdoc IEssenceMiddleware
    function postProcess(
        uint256,
        uint256,
        address,
        address,
        bytes calldata
    ) external {
        // do nothing
    }
}
