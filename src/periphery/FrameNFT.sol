// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { Pausable } from "../dependencies/openzeppelin/Pausable.sol";
import { Owned } from "../dependencies/solmate/Owned.sol";

import { IUpgradeable } from "../interfaces/IUpgradeable.sol";
import { IFrameEvents } from "../interfaces/IFrameEvents.sol";

import { Constants } from "../libraries/Constants.sol";
import { DataTypes } from "../libraries/DataTypes.sol";

import { CyberNFTBase } from "../base/CyberNFTBase.sol";
import { FrameNFTStorage } from "../storages/FrameNFTStorage.sol";

/**
 * @title Frame NFT
 * @author CyberConnect
 * @notice This contract is used to create Frame NFT.
 */
contract FrameNFT is
    Pausable,
    CyberNFTBase,
    UUPSUpgradeable,
    Owned,
    FrameNFTStorage,
    IUpgradeable,
    IFrameEvents
{
    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the Frame NFT.
     * @param owner The owner to set for the Frame NFT.
     * @param name The name to set for the Frame NFT.
     * @param symbol The symbol to set for the Frame NFT.
     */
    function initialize(
        address owner,
        string calldata name,
        string calldata symbol,
        string calldata uri
    ) external initializer {
        _tokenURI = uri;

        _pause();

        CyberNFTBase._initialize(name, symbol);
        Owned.__Owned_Init(owner);
        emit Initialize(owner, name, symbol, uri);
    }

    /**
     * @notice Changes the pause state of the Frame nft.
     *
     * @param toPause The pause state.
     */
    function pause(bool toPause) external onlyOwner {
        if (toPause) {
            super._pause();
        } else {
            super._unpause();
        }
    }

    /**
     * @notice Contract version number.
     *
     * @return uint256 The version number.
     * @dev This contract can be upgraded with UUPS upgradeability
     */
    function version() external pure virtual override returns (uint256) {
        return _VERSION;
    }

    /**
     * @notice Claims a Frame nft for an address.
     *
     * @param to The claimer address.
     * @return uint256 The token id.
     */
    function claim(address to) external returns (uint256) {
        require(msg.sender == _MBAddr);

        uint256 tokenId = super._mint(to);
        emit Claim(to, tokenId);

        return tokenId;
    }

    /**
     * @notice Sets the new tokenURI.
     *
     * @param uri The tokenURI.
     */
    function setTokenURI(string calldata uri) external onlyOwner {
        _tokenURI = uri;
    }

    /**
     * @notice Sets the new MB contract address.
     *
     * @param MBAddr The MB NFT address.
     */
    function setMBAddress(address MBAddr) external onlyOwner {
        _MBAddr = MBAddr;
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Transfers the Frame nft.
     *
     * @param from The initial owner address.
     * @param to The receipient address.
     * @param id The nft id.
     * @dev It requires the state to be unpaused
     */
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override whenNotPaused {
        super.transferFrom(from, to, id);
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC VIEW
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Generates the metadata json object.
     *
     * @param tokenId The profile NFT token ID.
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
        return _tokenURI;
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    // UUPS upgradeability
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
