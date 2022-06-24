// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { CyberNFTBase } from "./base/CyberNFTBase.sol";
import { ICyberEngine } from "./interfaces/ICyberEngine.sol";
import { ISubscribeNFT } from "./interfaces/ISubscribeNFT.sol";
import { IProfileNFT } from "./interfaces/IProfileNFT.sol";
import { Constants } from "./libraries/Constants.sol";
import { LibString } from "./libraries/LibString.sol";
import { ErrorMessages } from "./libraries/ErrorMessages.sol";

// This will be deployed as beacon contracts for gas efficiency
contract SubscribeNFT is CyberNFTBase, ISubscribeNFT {
    // TODO: use address or ICyberEngine
    address public immutable ENGINE;
    address public immutable PROFILE_NFT;

    uint256 internal _profileId;

    constructor(address engine, address profileNFT) {
        require(engine != address(0), ErrorMessages._ZERO_ENGINE_ADDRESS);
        require(
            profileNFT != address(0),
            ErrorMessages._ZERO_PROFILE_NFT_ADDRESS
        );
        ENGINE = engine;
        PROFILE_NFT = profileNFT;
        _disableInitializers();
    }

    function initialize(uint256 profileId) external initializer {
        _profileId = profileId;
        // Don't need to initialize CyberNFTBase with name and symbol since they are dynamic
    }

    function mint(address to) external returns (uint256) {
        require(msg.sender == address(ENGINE), ErrorMessages._ENGINE_MINT);
        super._mint(to);
        return _totalCount;
    }

    function name() external view override returns (string memory) {
        string memory handle = IProfileNFT(PROFILE_NFT).getHandleByProfileId(
            _profileId
        );
        return
            string(
                abi.encodePacked(handle, Constants._SUBSCRIBE_NFT_NAME_SUFFIX)
            );
    }

    function symbol() external view override returns (string memory) {
        string memory handle = IProfileNFT(PROFILE_NFT).getHandleByProfileId(
            _profileId
        );
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
        return ICyberEngine(ENGINE).getSubscribeNFTTokenURI(_profileId);
    }

    // Subscribe NFT cannot be transferred
    function transferFrom(
        address,
        address,
        uint256
    ) public pure override {
        revert(ErrorMessages._UNALLOWED_TRANSFER);
    }
}
