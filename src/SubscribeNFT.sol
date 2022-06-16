// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { CyberNFTBase } from "./base/CyberNFTBase.sol";
import { ICyberEngine } from "./interfaces/ICyberEngine.sol";

// This will be deployed as beacon contracts for gas efficiency
contract SubscribeNFT is CyberNFTBase {
    // TODO: use address or ICyberEngine
    ICyberEngine public immutable ENGINE;
    uint256 internal _profileId;

    constructor(address engine) {
        require(engine != address(0), "Beacon address cannot be 0");
        ENGINE = ICyberEngine(engine);
        _disableInitializers();
    }

    function initialize(uint256 profileId) external initializer {
        _profileId = profileId;
    }

    function mint(address to) external {
        super._mint(to);
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
