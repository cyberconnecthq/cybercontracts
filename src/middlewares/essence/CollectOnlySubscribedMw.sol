// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ERC721 } from "../../dependencies/solmate/ERC721.sol";
// import { DataTypes } from "../../libraries/DataTypes.sol";

import { IEssenceMiddleware } from "../../interfaces/IEssenceMiddleware.sol";
// import { ISubscribeNFT } from "../../interfaces/ISubscribeNFT.sol";

import { ProfileNFTStorage } from "../../storages/ProfileNFTStorage.sol";

/**
 * @title Collect only when subscribed Middleware
 * @author CyberConnect
 * @notice This contract is a middleware to allow the address to collect an essence only if they are subscribed
 */
contract CollectOnlySubscribedMw is IEssenceMiddleware, ProfileNFTStorage {
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
     * @notice Proccess that checks if the user is aready subscribed
     */
    function preProcess(
        uint256 profileId,
        uint256,
        address collector,
        address,
        bytes calldata
    ) external view override {
        address essenceOwnerSubscribeNFT = _subscribeByProfileId[profileId]
            .subscribeNFT;

        require(
            ERC721(essenceOwnerSubscribeNFT).balanceOf(collector) != 0,
            "Not subscribed to Essence owner"
        );
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
