// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface IFrameEvents {
    /**
     * @notice Emiited when the MB is initialized.
     *
     * @param owner The address of the MB owner.
     * @param name The name for the MB.
     * @param symbol The symbol for the MB.
     * @param uri The uri for the MB.
     */
    event Initialize(
        address indexed owner,
        string name,
        string symbol,
        string uri
    );

    /**
     * @notice Emitted when a frame NFT has been claimed.
     *
     * @param to The claimer address.
     * @param tokenId The token id for frame NFT.
     */
    event Claim(address indexed to, uint256 indexed tokenId);
}
