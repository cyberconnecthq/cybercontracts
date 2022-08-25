// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ERC721 } from "../../dependencies/solmate/ERC721.sol";

import { IEssenceMiddleware } from "../../interfaces/IEssenceMiddleware.sol";

import { EIP712 } from "../../base/EIP712.sol";

/**
 * @title Signiture Permission Essence Middleware
 * @author CyberConnect
 * @notice This contract is a middleware to allow an address to collect an essence only if they have a valid signiture from the
 * essence owner
 */
contract SignaturePermissionEssenceMw is IEssenceMiddleware, EIP712 {
    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/

    struct MiddlewareData {
        address signer;
        mapping(address => uint256) nonces;
    }

    bytes32 internal constant _ESSENCE_TYPEHASH =
        keccak256("mint(address to,uint256 nonce,uint256 deadline)");

    mapping(address => mapping(uint256 => mapping(uint256 => MiddlewareData)))
        internal _signerStorage;

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEssenceMiddleware
    function setEssenceMwData(
        uint256 profileId,
        uint256 essenceId,
        bytes calldata data
    ) external override returns (bytes memory) {
        _signerStorage[msg.sender][profileId][essenceId].signer = abi.decode(
            data,
            (address)
        );

        return new bytes(0);
    }

    /**
     * @inheritdoc IEssenceMiddleware
     * @notice Proccess that checks if the essence collector has the correct signature from the signer
     */
    function preProcess(
        uint256 profileId,
        uint256 essenceId,
        address collector,
        address,
        bytes calldata data
    ) external override {
        (uint8 v, bytes32 r, bytes32 s, uint256 deadline) = abi.decode(
            data,
            (uint8, bytes32, bytes32, uint256)
        );

        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        _ESSENCE_TYPEHASH,
                        collector,
                        _signerStorage[msg.sender][profileId][essenceId].nonces[
                            collector
                        ]++,
                        deadline
                    )
                )
            ),
            _signerStorage[msg.sender][profileId][essenceId].signer,
            v,
            r,
            s,
            deadline
        );
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
                            EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the nonce of the address.
     *
     * @param profileId The the user's profileId
     * @param essenceId The user address.
     * @return uint256 The nonce.
     */
    function getNonce(
        uint256 profileId,
        address collector,
        uint256 essenceId
    ) external view returns (uint256) {
        return
            _signerStorage[msg.sender][profileId][essenceId].nonces[collector];
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
        return "SignaturePermissionEssenceMw";
    }
}
