// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ERC721 } from "../dependencies/solmate/ERC721.sol";

import { ICyberNFTBase } from "../interfaces/ICyberNFTBase.sol";

import { Constants } from "../libraries/Constants.sol";
import { DataTypes } from "../libraries/DataTypes.sol";

import { EIP712 } from "./EIP712.sol";
import { Initializable } from "../upgradeability/Initializable.sol";

abstract contract CyberNFTBase is Initializable, EIP712, ERC721, ICyberNFTBase {
    uint256 internal _currentIndex = 0;
    uint256 internal _burnCount = 0;
    mapping(address => uint256) public nonces;

    constructor() {
        _disableInitializers();
    }

    /// @inheritdoc ICyberNFTBase
    function permit(
        address spender,
        uint256 tokenId,
        DataTypes.EIP712Signature calldata sig
    ) external override {
        address owner = ownerOf(tokenId);
        require(owner != spender, "CANNOT_PERMIT_OWNER");
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._PERMIT_TYPEHASH,
                        spender,
                        tokenId,
                        nonces[owner]++,
                        sig.deadline
                    )
                )
            ),
            owner,
            sig
        );

        getApproved[tokenId] = spender;
        emit Approval(owner, spender, tokenId);
    }

    /// @inheritdoc ICyberNFTBase
    function totalSupply() external view virtual override returns (uint256) {
        return _currentIndex - _burnCount;
    }

    /// @inheritdoc ICyberNFTBase
    function totalMinted() external view virtual override returns (uint256) {
        return _currentIndex;
    }

    /// @inheritdoc ICyberNFTBase
    function totalBurned() external view virtual override returns (uint256) {
        return _burnCount;
    }

    /// @inheritdoc ICyberNFTBase
    function burn(uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(
            msg.sender == owner || msg.sender == getApproved[tokenId],
            "NOT_OWNER_OR_APPROVED"
        );
        super._burn(tokenId);
        _burnCount++;
    }

    function _initialize(string calldata _name, string calldata _symbol)
        internal
        onlyInitializing
    {
        ERC721.__ERC721_Init(_name, _symbol);
    }

    function _mint(address _to) internal virtual returns (uint256) {
        super._safeMint(_to, ++_currentIndex);
        return _currentIndex;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf[tokenId] != address(0);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "NOT_MINTED");
    }

    function _domainSeperatorName()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return name;
    }
}
