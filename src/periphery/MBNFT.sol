// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { Pausable } from "../dependencies/openzeppelin/Pausable.sol";
import { Owned } from "../dependencies/solmate/Owned.sol";

import { IUpgradeable } from "../interfaces/IUpgradeable.sol";
import { IMB } from "../interfaces/IMB.sol";

import { Constants } from "../libraries/Constants.sol";
import { DataTypes } from "../libraries/DataTypes.sol";

import { CyberNFTBase } from "../base/CyberNFTBase.sol";
import { FrameNFT } from "../periphery/FrameNFT.sol";
import { MBNFTStorage } from "../storages/MBNFTStorage.sol";

/**
 * @title MB NFT
 * @author CyberConnect
 * @notice This contract is used to create MB NFT.
 */
contract MBNFT is
    Pausable,
    CyberNFTBase,
    UUPSUpgradeable,
    Owned,
    MBNFTStorage,
    IUpgradeable,
    IMB
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
     * @notice Initializes the MB NFT.
     * @param owner The owner to set for the MB NFT.
     * @param boxAddr The box NFT contract address.
     * @param frameAddr the frame NFT contract address.
     * @param name The name to set for the MB NFT.
     * @param symbol The symbol to set for the MB NFT.
     */
    function initialize(
        address owner,
        address boxAddr,
        address frameAddr,
        string calldata name,
        string calldata symbol,
        string calldata uri
    ) external initializer {
        _boxAddr = boxAddr;
        _frameAddr = frameAddr;
        _tokenURI = uri;

        _pause();

        CyberNFTBase._initialize(name, symbol);
        Owned.__Owned_Init(owner);

        emit Initialize(owner, boxAddr, frameAddr, name, symbol, uri);
    }

    /**
     * @notice Changes the pause state of the box nft.
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
     * @notice Open a box NFT.
     *
     * @param boxId The box NFT tokenID.
     */
    function openBox(uint256 boxId) external {
        address to = CyberNFTBase(_boxAddr).ownerOf(boxId);
        require(to == msg.sender);

        CyberNFTBase(_boxAddr).burn(boxId);

        uint256 MBTokenId = super._mint(to);

        uint256 frameTokenId = FrameNFT(_frameAddr).claim(to);

        emit OpenBox(to, MBTokenId, frameTokenId);
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
     * @notice Sets the new box and frame contract address.
     *
     * @param boxAddr The box NFT address.
     * @param frameAddr The frame NFT address.
     */
    function setBoxAndFrameAddr(address boxAddr, address frameAddr)
        external
        onlyOwner
    {
        _boxAddr = boxAddr;
        _frameAddr = frameAddr;
    }

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the Box address.
     *
     * @return address The Box address.
     */
    function getBoxAddr() external view override returns (address) {
        return _boxAddr;
    }

    /**
     * @notice Gets the Frame address.
     *
     * @return address The Frame address.
     */
    function getFrameAddr() external view override returns (address) {
        return _frameAddr;
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Transfers the box nft.
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
