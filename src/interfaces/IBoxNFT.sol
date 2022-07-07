// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface IBoxNFT {
    /**
     * @notice Mints the Box NFT.
     *
     * @param _to The recipient address.
     * @return uint256 The token id.
     */
    function mint(address _to) external returns (uint256);
}
