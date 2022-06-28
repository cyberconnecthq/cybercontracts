// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

interface IBoxNFT {
    /**
     * @notice Mints the Box NFT.
     *
     * @param _to recipient address.
     * @return uint256 token id.
     */
    function mint(address _to) external returns (uint256);
}
