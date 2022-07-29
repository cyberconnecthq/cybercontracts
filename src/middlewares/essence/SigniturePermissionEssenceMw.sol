// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ERC721 } from "../../dependencies/solmate/ERC721.sol";

import { IEssenceMiddleware } from "../../interfaces/IEssenceMiddleware.sol";

import { EIP712 } from "../../base/EIP712.sol";

/**
 * @title Signiture Permission Essence Middleware
 * @author CyberConnect
 * @notice This contract is a middleware to allow the address to collect an essence only if have a valid signiture
 */
contract CollectOnlySubscribedMw is IEssenceMiddleware, EIP712 {
    struct MiddlewareData {
        address signer;
        uint256 nonce;
    }

    mapping(address => mapping(uint256 => mapping(uint256 => MiddlewareData))) signerStorage;

    bytes32 internal constant _ESSENCE_TYPEHASH =
        keccak256("mint(address to,uint256 nonce,uint256 deadline)");

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEssenceMiddleware
    function setEssenceMwData(
        uint256 profileId,
        uint256 essenceId,
        bytes calldata data
    ) external override returns (bytes memory) {
        signerStorage[msg.sender][profileId][essenceId] = abi.decode(
            data,
            (MiddlewareData)
        );
        return new bytes(0);
    }

    /**
     * @inheritdoc IEssenceMiddleware
     * @notice Proccess that checks if the user is aready subscribed to the essence owner
     */
    function preProcess(
        uint256 profileId,
        uint256 essenceId,
        address collector,
        address,
        bytes calldata data
    ) external override {
        MiddlewareData storage mwData = signerStorage[msg.sender][profileId][
            essenceId
        ];

        (uint8 v, bytes32 r, bytes32 s, uint256 deadline) = abi.decode(
            data,
            (uint8, bytes32, bytes32, uint256)
        );

        _requiresValidSig(collector, v, r, s, deadline, mwData);
    }

    /// @inheritdoc IEssenceMiddleware
    function postProcess(
        uint256,
        uint256,
        address,
        address,
        bytes calldata
    ) external {
        // do nothing
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _domainSeperatorName()
        internal
        pure
        override
        returns (string memory)
    {
        return "CollectOnlySubscribedMw";
    }

    function _requiresValidSig(
        address to,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 deadline,
        MiddlewareData storage mwData
    ) internal {
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(_ESSENCE_TYPEHASH, to, mwData.nonce++, deadline)
                )
            ),
            mwData.signer,
            v,
            r,
            s,
            deadline
        );
    }
}
