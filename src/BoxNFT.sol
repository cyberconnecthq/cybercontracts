// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { IBoxNFT } from "./interfaces/IBoxNFT.sol";
import { CyberNFTBase } from "./base/CyberNFTBase.sol";
import { RolesAuthority } from "./dependencies/solmate/RolesAuthority.sol";
import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { IUpgradeable } from "./interfaces/IUpgradeable.sol";

/**
 * @title Box NFT
 * @author CyberConnect
 * @notice This contract is used to create Box NFT.
 */
contract BoxNFT is CyberNFTBase, IBoxNFT, IUpgradeable, UUPSUpgradeable {
    address public immutable ENGINE;
    uint256 private constant VERSION = 1;

    modifier onlyEngine() {
        require(msg.sender == address(ENGINE), "Only Engine");
        _;
    }

    // ENGINE for mint
    constructor(address _engine) {
        require(_engine != address(0), "Engine address cannot be 0");
        ENGINE = _engine;
    }

    /**
     * @notice Initializes the Box NFT.
     *
     * @param _name name to set for the Box NFT.
     * @param _symbol symbol to set for the Box NFT.
     */
    function initialize(string calldata _name, string calldata _symbol)
        external
        initializer
    {
        CyberNFTBase._initialize(_name, _symbol);
    }

    /// @inheritdoc IBoxNFT
    function mint(address _to) external onlyEngine returns (uint256) {
        super._mint(_to);
        return _totalCount;
    }

    /**
     * @notice Generates the metadata json object.
     *
     * @param tokenId The profile NFT token ID.
     * @return memory the metadata json object.
     * @dev it requires the tokenId to be already minted.
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

    // TODO: write a test for upgrade box nft
    // UUPS upgradeability
    function version() external pure virtual override returns (uint256) {
        return VERSION;
    }

    // UUPS upgradeability
    function _authorizeUpgrade(address) internal override onlyEngine {}
}
