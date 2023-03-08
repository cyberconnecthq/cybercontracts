// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import { IEssenceMiddleware } from "../../interfaces/IEssenceMiddleware.sol";

import { DataTypes } from "../../libraries/DataTypes.sol";
import { Constants } from "../../libraries/Constants.sol";

import { EIP712 } from "../../base/EIP712.sol";
import { FeeMw } from "../base/FeeMw.sol";

/**
 * @title Collect Permission Paid Middleware
 * @author CyberConnect
 * @notice This contract is a middleware to allow an address to collect an essence only if they have a valid signiture from the
 * signer and pay certain fees.
 */
contract CollectPermissionPaidMw is IEssenceMiddleware, EIP712, FeeMw {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                EVENT
    //////////////////////////////////////////////////////////////*/

    event CollectPermissionPaidMwSet(
        address indexed namespace,
        uint256 indexed profileId,
        uint256 indexed essenceId,
        address signer,
        uint256 totalSupply,
        uint256 amount,
        address recipient,
        address currency
    );

    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/

    struct MiddlewareData {
        address signer;
        mapping(address => uint256) nonces;
        uint256 totalSupply;
        uint256 currentCollect;
        uint256 amount;
        address recipient;
        address currency;
    }

    bytes32 internal constant _ESSENCE_TYPEHASH =
        keccak256(
            "mint(address to,uint256 profileId,uint256 essenceId,uint256 nonce,uint256 deadline)"
        );

    mapping(address => mapping(uint256 => mapping(uint256 => MiddlewareData)))
        internal _signerStorage;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address treasury) FeeMw(treasury) {}

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEssenceMiddleware
    function setEssenceMwData(
        uint256 profileId,
        uint256 essenceId,
        bytes calldata data
    ) external override returns (bytes memory) {
        (
            uint256 totalSupply,
            uint256 amount,
            address recipient,
            address currency,
            address signer
        ) = abi.decode(data, (uint256, uint256, address, address, address));

        require(recipient != address(0), "INVALID_ADDRESS");
        require(
            amount == 0 || _currencyAllowed(currency),
            "CURRENCY_NOT_ALLOWED"
        );

        _signerStorage[msg.sender][profileId][essenceId].signer = signer;
        _signerStorage[msg.sender][profileId][essenceId]
            .totalSupply = totalSupply;
        _signerStorage[msg.sender][profileId][essenceId].amount = amount;
        _signerStorage[msg.sender][profileId][essenceId].recipient = recipient;
        _signerStorage[msg.sender][profileId][essenceId].currency = currency;

        emit CollectPermissionPaidMwSet(
            msg.sender,
            profileId,
            essenceId,
            signer,
            totalSupply,
            amount,
            recipient,
            currency
        );

        return new bytes(0);
    }

    /**
     * @inheritdoc IEssenceMiddleware
     * @notice Process that checks if the essence collector has the correct signature from the signer
     */
    function preProcess(
        uint256 profileId,
        uint256 essenceId,
        address collector,
        address,
        bytes calldata data
    ) external override {
        require(
            _signerStorage[msg.sender][profileId][essenceId].totalSupply >
                _signerStorage[msg.sender][profileId][essenceId].currentCollect,
            "COLLECT_LIMIT_EXCEEDED"
        );

        DataTypes.EIP712Signature memory sig;

        (sig.v, sig.r, sig.s, sig.deadline) = abi.decode(
            data,
            (uint8, bytes32, bytes32, uint256)
        );

        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        _ESSENCE_TYPEHASH,
                        collector,
                        profileId,
                        essenceId,
                        _signerStorage[msg.sender][profileId][essenceId].nonces[
                                collector
                            ]++,
                        sig.deadline
                    )
                )
            ),
            _signerStorage[msg.sender][profileId][essenceId].signer,
            sig.v,
            sig.r,
            sig.s,
            sig.deadline
        );

        uint256 amount = _signerStorage[msg.sender][profileId][essenceId]
            .amount;

        if (amount > 0) {
            address currency = _signerStorage[msg.sender][profileId][essenceId]
                .currency;
            uint256 treasuryCollected = (amount * _treasuryFee()) /
                Constants._MAX_BPS;
            uint256 actualPaid = amount - treasuryCollected;

            IERC20(currency).safeTransferFrom(
                collector,
                _signerStorage[msg.sender][profileId][essenceId].recipient,
                actualPaid
            );

            if (treasuryCollected > 0) {
                IERC20(currency).safeTransferFrom(
                    collector,
                    _treasuryAddress(),
                    treasuryCollected
                );
            }
        }

        _signerStorage[msg.sender][profileId][essenceId].currentCollect++;
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
        address namespace,
        uint256 profileId,
        address collector,
        uint256 essenceId
    ) external view returns (uint256) {
        return
            _signerStorage[namespace][profileId][essenceId].nonces[collector];
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _domainSeparatorName()
        internal
        pure
        override
        returns (string memory)
    {
        return "CollectPermissionPaidMw";
    }
}
