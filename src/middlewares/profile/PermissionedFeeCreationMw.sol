// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import { IProfileMiddleware } from "../../interfaces/IProfileMiddleware.sol";
import { PermissionedMw } from "../base/PermissionedMw.sol";
import { PaymentMw } from "../base/PaymentMw.sol";
import { DataTypes } from "../../libraries/DataTypes.sol";
import { Constants } from "../../libraries/Constants.sol";
import { EIP712 } from "../../dependencies/openzeppelin/EIP712.sol";

/**
 * @title Profile Fee Creation Middleware
 * @author Link3
 * @notice This contract is a middleware to allow one address to create profile with certain fees.
 */
contract PermissionedFeeCreationMw is
    IProfileMiddleware,
    EIP712,
    PermissionedMw,
    PaymentMw
{
    using SafeERC20 for IERC20;

    constructor(address engine) PermissionedMw(engine) {}

    // TODO re-think put all under same strcut & inernal?
    mapping(address => mapping(address => uint256)) public noncesByNamespace;
    mapping(address => mapping(DataTypes.Tier => uint256))
        public feeMappingByNamespace;
    mapping(address => address) public signerByNamespace;

    // TODO more generic way to express this
    uint256 internal constant _INITIAL_FEE_TIER0 = 10 ether;
    uint256 internal constant _INITIAL_FEE_TIER1 = 2 ether;
    uint256 internal constant _INITIAL_FEE_TIER2 = 1 ether;
    uint256 internal constant _INITIAL_FEE_TIER3 = 0.5 ether;
    uint256 internal constant _INITIAL_FEE_TIER4 = 0.1 ether;
    uint256 internal constant _INITIAL_FEE_TIER5 = 0.01 ether;

    // TODO maybe pass in initial call data?
    // initialize the middlware for a given namespace
    function initializeMw(
        address profileAddr,
        address currency,
        address recipient
    ) external onlyNamespaceOwner(profileAddr) {
        require(recipient != address(0), "ZERO_RECIPENT_ADDRESS");

        // TODO think how we manage currency whitelist
        //require(currencyWhitelisted(currency), "INVALID_CURRENCY");
        _setPaymentMethod(profileAddr, currency, recipient);

        _setFeeByTier(profileAddr, DataTypes.Tier.Tier0, _INITIAL_FEE_TIER0);
        _setFeeByTier(profileAddr, DataTypes.Tier.Tier1, _INITIAL_FEE_TIER1);
        _setFeeByTier(profileAddr, DataTypes.Tier.Tier2, _INITIAL_FEE_TIER2);
        _setFeeByTier(profileAddr, DataTypes.Tier.Tier3, _INITIAL_FEE_TIER3);
        _setFeeByTier(profileAddr, DataTypes.Tier.Tier4, _INITIAL_FEE_TIER4);
        _setFeeByTier(profileAddr, DataTypes.Tier.Tier5, _INITIAL_FEE_TIER5);
    }

    /**
     * @notice Sets the tier fee.
     *
     * @param tier The tier number.
     * @param amount The fee amount.
     */
    function setFeeByTier(
        address profileAddr,
        DataTypes.Tier tier,
        uint256 amount
    ) external onlyNamespaceOwner(profileAddr) {
        _setFeeByTier(profileAddr, tier, amount);
    }

    /**
     * @notice Sets the new signer address.
     *
     * @param signer The signer address.
     * @dev The address can not be zero address.
     */
    function setSigner(address profileAddr, address signer)
        external
        onlyNamespaceOwner(profileAddr)
    {
        require(signer != address(0), "ZERO_SIGNER_ADDRESS");
        address preSigner = signerByNamespace[profileAddr];
        signerByNamespace[profileAddr] = signer;

        //emit SetSigner(preSigner, signer);
    }

    function _setFeeByTier(
        address profileAddr,
        DataTypes.Tier tier,
        uint256 amount
    ) internal {
        uint256 preAmount = feeMappingByNamespace[profileAddr][tier];
        feeMappingByNamespace[profileAddr][tier] = amount;

        //emit SetFeeByTier(tier, preAmount, amount);
    }

    function _requiresEnoughFee(
        address profileAddr,
        string calldata handle,
        uint256 amount
    ) internal view {
        bytes memory byteHandle = bytes(handle);
        uint256 fee = feeMappingByNamespace[DataTypes.Tier.Tier5];

        require(byteHandle.length >= 1, "Invalid handle length");
        if (byteHandle.length < 6) {
            fee = feeMappingByNamespace[DataTypes.Tier(byteHandle.length - 1)];
        }
        require(amount >= fee, "Insufficient fee");
    }

    function _requiresExpectedSigner(
        bytes32 digest,
        address expectedSigner,
        DataTypes.EIP712Signature calldata sig
    ) internal view {
        require(sig.deadline >= block.timestamp, "DEADLINE_EXCEEDED");
        address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);
        require(recoveredAddress == expectedSigner, "INVALID_SIGNATURE");
    }

    /**
     * @inheritdoc IProfileMiddleware
     */
    function preProcess(
        uint256 fee,
        DataTypes.CreateProfileParams calldata params
    ) external {
        // TODO: check if safe use msg.sender, do we need onlyProfile?
        address memory profileAddr = msg.sender;
        _requiresEnoughFee(profileAddr, params.handle, fee);
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._CREATE_PROFILE_TYPEHASH,
                        params.to,
                        keccak256(bytes(params.handle)),
                        keccak256(bytes(params.avatar)),
                        keccak256(bytes(params.metadata)),
                        noncesByNamespace[profileAddr][params.to]++,
                        params.sig.deadline
                    )
                )
            ),
            signerByNamespace[profileAddr],
            params.sig
        );

        string memory payment = _getPaymentMethod(profileAddr);
        IERC20(payment.currency).safeTransferFrom(
            profileAddr,
            payment.recipient,
            fee
        );
    }

    /// @inheritdoc IProfileMiddleware
    function postProcess(
        uint256 fee,
        DataTypes.CreateProfileParams calldata params
    ) external {
        // do nothing
    }
}
