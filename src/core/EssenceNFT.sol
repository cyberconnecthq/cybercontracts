// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { CyberNFTBase } from "../base/CyberNFTBase.sol";
import { IProfileNFT } from "../interfaces/IProfileNFT.sol";
import { EssenceNFTStorage } from "../storages/EssenceNFTStorage.sol";
import { IUpgradeable } from "../interfaces/IUpgradeable.sol";

contract EssenceNFT is CyberNFTBase, EssenceNFTStorage, IUpgradeable {
    address public immutable PROFILE; // solhint-disable-line

    constructor(address profile) {
        require(profile != address(0), "ZERO_ADDRESS");
        PROFILE = profile;
        _disableInitializers();
    }

    function initialize(
        uint256 profileId,
        uint256 essenceId,
        string calldata name,
        string calldata symbol
    ) external initializer {
        _profileId = profileId;
        _essenceId = essenceId;
        CyberNFTBase._initialize(name, symbol);
    }

    function mint(address to) external returns (uint256) {
        require(msg.sender == PROFILE, "ONLY_PROFILE");
        return super._mint(to);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        return
            IProfileNFT(PROFILE).getEssenceNFTTokenURI(_profileId, _essenceId);
    }

    function version() external pure override returns (uint256) {
        return _VERSION;
    }
}
