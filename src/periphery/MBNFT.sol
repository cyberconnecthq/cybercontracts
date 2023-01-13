// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { Pausable } from "../dependencies/openzeppelin/Pausable.sol";
import { Owned } from "../dependencies/solmate/Owned.sol";

import { IUpgradeable } from "../interfaces/IUpgradeable.sol";
import { IMB } from "../interfaces/IMB.sol";

import { Constants } from "../libraries/Constants.sol";
import { DataTypes } from "../libraries/DataTypes.sol";
import { LibString } from "../libraries/LibString.sol";

import { CyberNFTBaseFlex } from "../base/CyberNFTBaseFlex.sol";
import { CyberNFTBase } from "../base/CyberNFTBase.sol";
import { MBNFTStorage } from "../storages/MBNFTStorage.sol";

/**
 * @title MB NFT
 * @author CyberConnect
 * @notice This contract is used to create MB NFT.
 */
contract MBNFT is
    Pausable,
    CyberNFTBaseFlex,
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
     * @param name The name to set for the MB NFT.
     * @param symbol The symbol to set for the MB NFT.
     */
    function initialize(
        address owner,
        address boxAddr,
        string calldata name,
        string calldata symbol,
        string calldata uri
    ) external initializer {
        _boxAddr = boxAddr;
        _tokenURI = uri;

        CyberNFTBaseFlex._initialize(name, symbol);
        Owned.__Owned_Init(owner);

        emit Initialize(owner, boxAddr, name, symbol, uri);
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
        require(to == msg.sender, "INCORRECT_SENDER");

        CyberNFTBase(_boxAddr).burn(boxId);

        super._mintTo(to, boxId);

        emit OpenBox(to, boxId);
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
     */
    function setBoxAddr(address boxAddr) external onlyOwner {
        _boxAddr = boxAddr;
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
        return
            string(
                abi.encodePacked(_tokenURI, "/", LibString.toString(tokenId))
            );
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    // UUPS upgradeability
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
