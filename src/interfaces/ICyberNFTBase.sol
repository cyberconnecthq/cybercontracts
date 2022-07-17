// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface ICyberNFTBase {
    /**
     * @notice Gets the total supply for the CyberNFT.
     *
     * @return uint256 The total supply.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice The EIP-712 permit function.
     *
     * @param spender The spender address.
     * @param tokenId The token ID to approve.
     * @param sig Must produce valid EIP712 signature with `s`, `r`, `v` and `deadline`.
     */
    function permit(
        address spender,
        uint256 tokenId,
        DataTypes.EIP712Signature calldata sig
    ) external;
}
