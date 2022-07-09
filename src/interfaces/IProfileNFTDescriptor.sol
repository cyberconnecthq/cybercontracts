// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface IProfileNFTDescriptor {
    function setAnimationTemplate(string calldata template) external;

    /**
     * @notice Generate the Profile NFT Token URI.
     *
     * @param params The dependences of token URI.
     * @return string The token URI.
     */
    function tokenURI(DataTypes.ConstructTokenURIParams calldata params)
        external
        view
        returns (string memory);
}
