// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface IEssenceMiddleware {
    /**
     * @notice Proccess that runs before the essenceeNFT mint happens.
     *
     * @param profileId The profile Id.
     * @param essenceId The essence Id.
     * @param collector The collector address.
     * @param essenceNFT The essence nft address.
     * @param data Extra data to process.
     */
    function preProcess(
        uint256 profileId,
        uint256 essenceId,
        address collector,
        address essenceNFT,
        bytes calldata data
    ) external;

    /**
     * @notice Proccess that runs after the essenceeNFT mint happens.
     *
     * @param profileId The profile Id.
     * @param essenceId The essence Id.
     * @param collector The collector address.
     * @param essenceNFT The essence nft address.
     * @param data Extra data to process.
     */
    function postProcess(
        uint256 profileId,
        uint256 essenceId,
        address collector,
        address essenceNFT,
        bytes calldata data
    ) external;

    function prepare(
        uint256 profileId,
        uint256 essenceId,
        bytes calldata prepareData
    ) external returns (bytes memory);
}
