// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface ICyberGrandEvents {
    /**
     * @notice Emiited when the CyberGrand is initialized.
     *
     * @param owner The address of the CyberGrand owner.
     * @param name The name for the CyberGrand.
     * @param symbol The symbol for the CyberGrand.
     */
    event Initialize(address indexed owner, string name, string symbol);

    /**
     * @notice Emitted when a new signer has been set.
     *
     * @param preSigner The previous signer address.
     * @param newSigner The newly set signer address.
     */
    event SetSigner(address indexed preSigner, address indexed newSigner);

    /**
     * @notice Emitted when a grand nft has been claimed.
     *
     * @param to The claimer address.
     * @param tokenId The token id that has been claimed.
     */
    event ClaimGrand(address indexed to, uint256 indexed tokenId);
}
