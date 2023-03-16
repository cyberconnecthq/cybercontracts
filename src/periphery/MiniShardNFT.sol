// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/presets/ERC1155PresetMinterPauser.sol)

pragma solidity ^0.8.0;

import { ERC1155 } from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import { ERC1155Burnable } from "openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import { ERC1155Pausable } from "openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import { AccessControlEnumerable } from "openzeppelin-contracts/contracts/access/AccessControlEnumerable.sol";
import { Context } from "openzeppelin-contracts/contracts/utils/Context.sol";
import { LibString } from "../libraries/LibString.sol";
import { EIP712 } from "../base/EIP712.sol";
import { DataTypes } from "../libraries/DataTypes.sol";

/**
 * @dev {ERC1155} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 *
 */
contract MiniShardNFT is
    Context,
    AccessControlEnumerable,
    ERC1155Burnable,
    ERC1155Pausable,
    EIP712
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    address internal _signer;
    mapping(address => uint256) internal _nonces;

    bytes32 internal constant _MINT_TYPEHASH =
        keccak256(
            "mint(address to,uint256 id,uint256 amount,uint256 nonce,uint256 deadline)"
        );

    bytes32 internal constant _MINT_BATCH_TYPEHASH =
        keccak256(
            "mintBatch(address to,uint256[] ids,uint256[] amounts,uint256 nonce,uint256 deadline)"
        );

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, and `PAUSER_ROLE` to the account that
     * deploys the contract.
     */
    constructor(string memory uri, address owner) ERC1155(uri) {
        _signer = owner;
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(MINTER_ROLE, owner);
        _setupRole(PAUSER_ROLE, owner);
    }

    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "ERC1155PresetMinterPauser: must have minter role to mint"
        );

        _mint(to, id, amount, data);
    }

    function mintWithSig(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data,
        DataTypes.EIP712Signature calldata sig
    ) public {
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        _MINT_TYPEHASH,
                        to,
                        id,
                        amount,
                        _nonces[to]++,
                        sig.deadline
                    )
                )
            ),
            _signer,
            sig
        );

        _mint(to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "ERC1155PresetMinterPauser: must have minter role to mint"
        );

        _mintBatch(to, ids, amounts, data);
    }

    function mintBatchWithSig(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data,
        DataTypes.EIP712Signature calldata sig
    ) public {
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        _MINT_BATCH_TYPEHASH,
                        to,
                        keccak256(abi.encodePacked(ids)),
                        keccak256(abi.encodePacked(amounts)),
                        _nonces[to]++,
                        sig.deadline
                    )
                )
            ),
            _signer,
            sig
        );

        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "ERC1155PresetMinterPauser: must have pauser role to pause"
        );
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "ERC1155PresetMinterPauser: must have pauser role to unpause"
        );
        _unpause();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Pausable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function uri(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(super.uri(id), "/", LibString.toString(id))
            );
    }

    function getNonce(address user) external view returns (uint256) {
        return _nonces[user];
    }

    function _domainSeparatorName()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return "MiniShard";
    }
}
