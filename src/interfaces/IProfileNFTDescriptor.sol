// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

interface IProfileNFTDescriptor {
    struct ConstructTokenURIParams {
        uint256 tokenId;
        string handle;
        uint256 subscribers;
    }

    function setAnimationTemplate(string calldata template) external;

    /**
     * @notice Generate the Profile NFT Token URI.
     *
     * @param params The dependences of token URI.
     * @return string The token URI.
     */
    function tokenURI(ConstructTokenURIParams calldata params)
        external
        view
        returns (string memory);
}
