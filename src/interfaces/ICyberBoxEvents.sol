// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface ICyberBoxEvents {
    /**
     * @dev Emitted when a new signer has been set.
     *
     * @param preSigner The previous signer address.
     * @param newSigner The newly set signer address.
     */
    event SetSigner(address indexed preSigner, address indexed newSigner);

    /**
     * @dev Emitted when a new owner has been set.
     *
     * @param preOwner The previous owner address.
     * @param newOwner The newly set owner address.
     */
    event SetOwner(address indexed preOwner, address indexed newOwner);

    /**
     * @notice Emitted when a profile claims a box nft.
     *
     * @param to The claimer address.
     * @param boxId The box id that has been claimed.
     */
    event ClaimBox(address indexed to, uint256 indexed boxId);
}
