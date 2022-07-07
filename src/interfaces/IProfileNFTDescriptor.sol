// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

interface IProfileNFTDescriptor {
    /**
     * @notice Mints the Box NFT.
     *
     * @param _to The recipient address.
     * @return uint256 The token id.
     */

    struct ConstructTokenURIParams {
        uint256 tokenId;
        string handle;
        string imageURL;
        string animationURL;
        uint256 subscribers;
    }

    function tokenURI(ConstructTokenURIParams calldata params)
        external
        view
        returns (string memory);
}
