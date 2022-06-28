// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { IBoxNFT } from "./interfaces/IBoxNFT.sol";
import { CyberNFTBase } from "./base/CyberNFTBase.sol";
import { RolesAuthority } from "./dependencies/solmate/RolesAuthority.sol";
import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { IUpgradeable } from "./interfaces/IUpgradeable.sol";
import { Pausable } from "./dependencies/openzeppelin/Pausable.sol";

contract BoxNFT is
    Pausable,
    CyberNFTBase,
    IBoxNFT,
    IUpgradeable,
    UUPSUpgradeable
{
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

    function initialize(string calldata _name, string calldata _symbol)
        external
        initializer
    {
        CyberNFTBase._initialize(_name, _symbol);
    }

    function mint(address _to) external onlyEngine returns (uint256) {
        super._mint(_to);
        return _totalCount;
    }

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

    // pausable
    function pause(bool toPause) external onlyEngine {
        if (toPause) {
            super._pause();
        } else {
            super._unpause();
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override whenNotPaused {
        super.transferFrom(from, to, id);
    }
}
