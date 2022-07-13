// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { EIP712 } from "./EIP712.sol";
import { ERC721 } from "../dependencies/solmate/ERC721.sol";

import { Constants } from "../libraries/Constants.sol";
import { DataTypes } from "../libraries/DataTypes.sol";

import { Initializable } from "../upgradeability/Initializable.sol";

// Sequential mint ERC721
abstract contract CyberNFTBase is Initializable, EIP712, ERC721 {
    bytes32 internal constant EIP712_REVISION_HASH = keccak256("1");

    uint256 internal _totalCount = 0;
    mapping(address => uint256) public nonces;

    constructor() {
        _disableInitializers();
    }

    function totalSupply() external view virtual returns (uint256) {
        return _totalCount;
    }

    function _initialize(string calldata _name, string calldata _symbol)
        internal
        onlyInitializing
    {
        ERC721.__ERC721_Init(_name, _symbol);
    }

    function _mint(address _to) internal virtual returns (uint256) {
        super._safeMint(_to, ++_totalCount);
        return _totalCount;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf[tokenId] != address(0);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "NOT_MINTED");
    }

    // Permit
    function permit(
        address spender,
        uint256 tokenId,
        DataTypes.EIP712Signature calldata sig
    ) external {
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
        // approve and emit
        getApproved[tokenId] = spender;
        emit Approval(owner, spender, tokenId);
    }

    function _domainSeperatorName()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return _name;
    }
}
