// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { CyberNFTBase } from "./base/CyberNFTBase.sol";
import { ICyberEngine } from "./interfaces/ICyberEngine.sol";
import { IProfileNFT } from "./interfaces/IProfileNFT.sol";
import { Constants } from "./libraries/Constants.sol";
import { LibString } from "./libraries/LibString.sol";

contract EssenceNFT is CyberNFTBase {
    ICyberEngine public immutable ENGINE;
    IProfileNFT public immutable PROFILE_NFT;

    uint256 internal _profileId;
    uint256 internal _essenceId;

    constructor(address engine, address profileNFT) {
        require(engine != address(0), "Engine address cannot be 0");
        require(profileNFT != address(0), "Profile NFT address cannot be 0");
        ENGINE = ICyberEngine(engine);
        PROFILE_NFT = IProfileNFT(profileNFT);
        _disableInitializers();
    }

    function initialize(uint256 profileId, uint256 essenceId)
        external
        initializer
    {
        _profileId = profileId;
        _essenceId = essenceId;
        // Don't need to initialize CyberNFTBase with name and symbol since they are dynamic
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        return ENGINE.essenceNFTTokenURI(_profileId, _essenceId);
    }

    function name() external view override returns (string memory) {
        string memory handle = PROFILE_NFT.getHandleByProfileId(_profileId);
        return
            string(
                abi.encodePacked(
                    handle,
                    Constants._ESSENCE_NFT_NAME_INFIX,
                    LibString.toString(_essenceId)
                )
            );
    }

    function symbol() external view override returns (string memory) {
        string memory handle = PROFILE_NFT.getHandleByProfileId(_profileId);
        return
            string(
                abi.encodePacked(
                    LibString.toUpper(handle),
                    Constants._ESSENCE_NFT_SYMBOL_INFIX,
                    LibString.toString(_essenceId)
                )
            );
    }

    function mint(address to) external {
        super._mint(to);
    }
}
