// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface ISubscribeNFT {
    /**
     * @notice Mints the Subscribe NFT.
     *
     * @param to The recipient address.
     * @return uint256 The token id.
     */
    function mint(address to) external returns (uint256);

    /**
     * @notice Initializes the Subscribe NFT.
     *
     * @param profileId The profile ID to set for the Subscribe NFT.
     */
    function initialize(
        uint256 profileId,
        string calldata name,
        string calldata symbol
    ) external;
}
