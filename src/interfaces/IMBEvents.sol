// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface IMBEvents {
    /**
     * @notice Emiited when the MB is initialized.
     *
     * @param owner The address of the MB owner.
     * @param boxAddr The address of the box NFT.
     * @param frameAddr The address of the frame NFT.
     * @param name The name for the MB.
     * @param symbol The symbol for the MB.
     * @param uri The uri for the MB.
     */
    event Initialize(
        address indexed owner,
        address indexed boxAddr,
        address indexed frameAddr,
        string name,
        string symbol,
        string uri
    );

    /**
     * @notice Emitted when a box NFT has been opened.
     *
     * @param to The claimer address.
     * @param MBTokenId The token id for MB NFT.
     * @param frameTokenId The token id for frame NFT.
     */
    event OpenBox(
        address indexed to,
        uint256 indexed MBTokenId,
        uint256 indexed frameTokenId
    );
}
