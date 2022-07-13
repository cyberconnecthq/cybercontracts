// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { Pausable } from "../dependencies/openzeppelin/Pausable.sol";
import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";

import { IUpgradeable } from "../interfaces/IUpgradeable.sol";
import { ICyberBoxEvents } from "../interfaces/ICyberBoxEvents.sol";

import { Constants } from "../libraries/Constants.sol";
import { DataTypes } from "../libraries/DataTypes.sol";

import { CyberNFTBase } from "../base/CyberNFTBase.sol";
import { CyberBoxNFTStorage } from "../storages/CyberBoxNFTStorage.sol";

/**
 * @title CyberBox NFT
 * @author CyberConnect
 * @notice This contract is used to create CyberBox NFT.
 */
contract CyberBoxNFT is
    Pausable,
    CyberNFTBase,
    UUPSUpgradeable,
    CyberBoxNFTStorage,
    IUpgradeable,
    ICyberBoxEvents
{
    /**
     * @notice Checks that sender is owner address.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    /**
     * @notice Initializes the Box NFT.
     *
     * @param _name_ The name to set for the Box NFT.
     * @param _symbol_ The symbol to set for the Box NFT.
     */
    function initialize(
        address _owner,
        string calldata _name_,
        string calldata _symbol_
    ) external initializer {
        CyberNFTBase._initialize(_name_, _symbol_);
        signer = _owner;
        owner = _owner;
        // start with paused
        _pause();
    }

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
        return "";
    }

    /**
     * @notice Contract version number.
     *
     * @return uint256 The version number.
     * @dev This contract can be upgraded with UUPS upgradeability
     */
    // TODO: write a test for upgrade box nft
    function version() external pure virtual override returns (uint256) {
        return _VERSION;
    }

    // UUPS upgradeability
    function _authorizeUpgrade(address) internal override onlyOwner {}

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
     * @notice Transfers the box nft.
     *
     * @param from The initial owner address.
     * @param to The receipient address.
     * @param from The nft id.
     * @dev It requires the state to be unpaused
     */
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override whenNotPaused {
        super.transferFrom(from, to, id);
    }

    /**
     * @notice Claims a CyberBox nft for an address.
     *
     * @param to The claimer address.
     * @param sig The EIP712 signature.
     * @return uint256 The box id.
     */
    function claimBox(address to, DataTypes.EIP712Signature calldata sig)
        external
        payable
        returns (uint256)
    {
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._CLAIM_BOX_TYPEHASH,
                        to,
                        nonces[to]++,
                        sig.deadline
                    )
                )
            ),
            signer,
            sig
        );

        uint256 boxId = super._mint(to);
        emit ClaimBox(to, boxId);

        return boxId;
    }

    /**
     * @notice Sets the new signer address.
     *
     * @param _signer The signer address.
     * @dev The address can not be zero address.
     */
    function setSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "zero address signer");
        address preSigner = signer;
        signer = _signer;

        emit SetSigner(preSigner, _signer);
    }

    /**
     * @notice Sets the new owner address.
     *
     * @param _owner The owner address.
     * @dev The address can not be zero address.
     */
    function setOwner(address _owner) external onlyOwner {
        require(_owner != address(0), "zero address owner");
        address preOwner = owner;
        owner = _owner;

        emit SetOwner(preOwner, _owner);
    }
}
