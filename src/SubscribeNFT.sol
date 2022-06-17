// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { CyberNFTBase } from "./base/CyberNFTBase.sol";
import { ICyberEngine } from "./interfaces/ICyberEngine.sol";
import { IProfileNFT } from "./interfaces/IProfileNFT.sol";
import { Constants } from "./libraries/Constants.sol";
import { LibString } from "./libraries/LibString.sol";

// This will be deployed as beacon contracts for gas efficiency
contract SubscribeNFT is CyberNFTBase {
    // TODO: use address or ICyberEngine
    ICyberEngine public immutable ENGINE;
    IProfileNFT public immutable PROFILE_NFT;

    uint256 internal _profileId;

    constructor(address engine, address profileNFT) {
        require(engine != address(0), "Engine address cannot be 0");
        require(profileNFT != address(0), "Profile NFT address cannot be 0");
        ENGINE = ICyberEngine(engine);
        PROFILE_NFT = IProfileNFT(profileNFT);
        _disableInitializers();
    }

    function initialize(uint256 profileId) external initializer {
        _profileId = profileId;
        // Don't need to initialize CyberNFTBase with name and symbol since they are dynamic
    }

    function mint(address to) external {
        require(msg.sender == address(ENGINE), "Only Engine could mint");
        super._mint(to);
    }

    function name() external view override returns (string memory) {
        string memory handle = PROFILE_NFT.getHandleByProfileId(_profileId);
        return
            string(
                abi.encodePacked(handle, Constants._SUBSCRIBE_NFT_NAME_SUFFIX)
            );
    }

    function symbol() external view override returns (string memory) {
        string memory handle = PROFILE_NFT.getHandleByProfileId(_profileId);
        return
            string(
                abi.encodePacked(
                    LibString.toUpper(handle),
                    Constants._SUBSCRIBE_NFT_SYMBOL_SUFFIX
                )
            );
    }

    function version() external pure virtual returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        return ENGINE.subscribeNFTTokenURI(_profileId);
    }
}
