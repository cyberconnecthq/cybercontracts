// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

interface ISubscribeMiddleware {
    // runs before the subscribeNFT mint happens
    function preProcess(
        uint256 profileId,
        address subscriber,
        address subscrbeNFT,
        bytes calldata data
    ) external;

    // runs after the subscribeNFT mint happens
    function postProcess(
        uint256 profileId,
        address subscriber,
        address subscrbeNFT,
        bytes calldata data
    ) external;
}
