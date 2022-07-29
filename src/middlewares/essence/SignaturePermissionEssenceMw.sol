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

    mapping(address => mapping(uint256 => mapping(uint256 => MiddlewareData)))
        internal _signerStorage;

    struct MiddlewareData {
        address signer;
        uint256 nonce;
    }
    uint256 internal _nonce;

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
        address signerAddr = abi.decode(data, (address));

        MiddlewareData memory params = MiddlewareData(signerAddr, _nonce);

        _signerStorage[msg.sender][profileId][essenceId] = params;

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
        MiddlewareData storage mwData = _signerStorage[msg.sender][profileId][
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
                            PUBLIC VIEW
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the nonce of the address.
     *
     * @param profileId The the user's profileId
     * @param essenceId The user address.
     * @return uint256 The nonce.
     */
    function getNonce(uint256 profileId, uint256 essenceId)
        external
        view
        returns (uint256)
    {
        return _signerStorage[msg.sender][profileId][essenceId].nonce;
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

    function _requiresValidSig(
        address collector,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 deadline,
        MiddlewareData storage mwData
    ) internal {
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        _ESSENCE_TYPEHASH,
                        collector,
                        mwData.nonce++,
                        deadline
                    )
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
