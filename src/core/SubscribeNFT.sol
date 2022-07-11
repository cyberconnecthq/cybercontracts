// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ISubscribeNFT } from "../interfaces/ISubscribeNFT.sol";
import { IProfileNFT } from "../interfaces/IProfileNFT.sol";
import { IUpgradeable } from "../interfaces/IUpgradeable.sol";

import { Constants } from "../libraries/Constants.sol";
import { LibString } from "../libraries/LibString.sol";

import { CyberNFTBase } from "../base/CyberNFTBase.sol";
import { SubscribeNFTStorage } from "../storages/SubscribeNFTStorage.sol";

/**
 * @title Subscribe NFT
 * @author CyberConnect
 * @notice This contract is used to create a Subscribe NFT.
 */
// This will be deployed as beacon contracts for gas efficiency
contract SubscribeNFT is
    CyberNFTBase,
    SubscribeNFTStorage,
    IUpgradeable,
    ISubscribeNFT
{
    address public immutable PROFILE; // solhint-disable-line

    constructor(address profile) {
        require(profile != address(0), "ZERO_ADDRESS");
        PROFILE = profile;
        _disableInitializers();
    }

    /// @inheritdoc ISubscribeNFT
    function initialize(
        uint256 profileId,
        string calldata name,
        string calldata symbol
    ) external override initializer {
        _profileId = profileId;
        CyberNFTBase._initialize(name, symbol);
    }

    /// @inheritdoc ISubscribeNFT
    function mint(address to) external override returns (uint256) {
        require(msg.sender == address(PROFILE), "Only profile could mint");
        return super._mint(to);
    }

    /**
     * @notice Contract version number.
     *
     * @return uint256 The version number.
     * @dev This contract can be upgraded with UUPS upgradeability
     */
    function version() external pure virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Generates the metadata json object.
     *
     * @param tokenId The NFT token ID.
     * @return string The metadata json object.
     * @dev It requires the tokenId to be already minted.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        return IProfileNFT(PROFILE).getSubscribeNFTTokenURI(_profileId);
    }

    /**
     * @notice Disallows the transfer of the subscribe nft.
     */
    function transferFrom(
        address,
        address,
        uint256
    ) public pure override {
        revert("Transfer is not allowed");
    }
}
