// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface ISubscribeMiddleware {
    /**
     * @notice Proccess that runs before the subscribeNFT mint happens.
     *
     * @param profileId The profile Id.
     * @param subscriber The subscriber address.
     * @param subscrbeNFT The subscribe nft address.
     * @param data The subscription data.
     */
    function preProcess(
        uint256 profileId,
        address subscriber,
        address subscrbeNFT,
        bytes calldata data
    ) external;

    /**
     * @notice Proccess that runs after the subscribeNFT mint happens.
     *
     * @param profileId The profile Id.
     * @param subscriber The subscriber address.
     * @param subscrbeNFT The subscribe nft address.
     * @param data The subscription data.
     */
    function postProcess(
        uint256 profileId,
        address subscriber,
        address subscrbeNFT,
        bytes calldata data
    ) external;
}
