// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { ICyberEngineEvents } from "./ICyberEngineEvents.sol";

interface ICyberEngine is ICyberEngineEvents {
    /**
     * @notice Gets the Subscribe NFT token URI.
     *
     * @param profileId The profile ID.
     * @return memory The Subscribe NFT token URI.
     */
    function getSubscribeNFTTokenURI(uint256 profileId)
        external
        view
        returns (string memory);

    /**
     * @notice Gets the Subscribe NFT address.
     *
     * @param profileId The profile ID.
     * @return address The Subscribe NFT address.
     */
    function getSubscribeNFT(uint256 profileId) external view returns (address);
}
