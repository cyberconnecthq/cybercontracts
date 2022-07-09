// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IProfileMiddleware } from "../../interfaces/IProfileMiddleware.sol";
import { DataTypes } from "../../libraries/DataTypes.sol";
import { Constants } from "../../libraries/Constants.sol";
import { EIP712 } from "../../dependencies/openzeppelin/EIP712.sol";

/**
 * @title Profile Fee Creation Middleware
 * @author Link3
 * @notice This contract is a middleware to allow one address to create profile with certain fees.
 */
contract FeeCreationMw is IProfileMiddleware, EIP712 {
    // TODO make this mw more generic, e.g. separate fee/signer logic
    constructor() {
        _setInitialFees();
        signer = msg.sender;
    }

    // TODO re-think this nonces and 712 stuff
    mapping(address => uint256) public nonces;
    mapping(DataTypes.Tier => uint256) public feeMapping;
    address public signer;

    // Initial States
    uint256 internal constant _INITIAL_FEE_TIER0 = 10 ether;
    uint256 internal constant _INITIAL_FEE_TIER1 = 2 ether;
    uint256 internal constant _INITIAL_FEE_TIER2 = 1 ether;
    uint256 internal constant _INITIAL_FEE_TIER3 = 0.5 ether;
    uint256 internal constant _INITIAL_FEE_TIER4 = 0.1 ether;
    uint256 internal constant _INITIAL_FEE_TIER5 = 0.01 ether;

    /**
     * @notice Sets the tier fee.
     *
     * @param tier The tier number.
     * @param amount The fee amount.
     */
    function _setFeeByTier(DataTypes.Tier tier, uint256 amount) internal {
        uint256 preAmount = feeMapping[tier];
        feeMapping[tier] = amount;

        //emit SetFeeByTier(tier, preAmount, amount);
    }

    // /**
    //  * @notice Sets the new signer address.
    //  *
    //  * @param _signer The signer address.
    //  * @dev The address can not be zero address.
    //  */
    // function setSigner(address _signer) external requiresAuth {
    //     require(_signer != address(0), "zero address signer");
    //     address preSigner = signer;
    //     signer = _signer;

    //     emit SetSigner(preSigner, _signer);
    // }

    /**
     * @notice Sets the initial tier fee.
     */
    function _setInitialFees() internal {
        _setFeeByTier(DataTypes.Tier.Tier0, _INITIAL_FEE_TIER0);
        _setFeeByTier(DataTypes.Tier.Tier1, _INITIAL_FEE_TIER1);
        _setFeeByTier(DataTypes.Tier.Tier2, _INITIAL_FEE_TIER2);
        _setFeeByTier(DataTypes.Tier.Tier3, _INITIAL_FEE_TIER3);
        _setFeeByTier(DataTypes.Tier.Tier4, _INITIAL_FEE_TIER4);
        _setFeeByTier(DataTypes.Tier.Tier5, _INITIAL_FEE_TIER5);
    }

    /**
     * @notice Checks if the fee is enough.
     *
     * @param handle The profile handle.
     * @param amount The msg value.
     */
    function _requiresEnoughFee(string calldata handle, uint256 amount)
        internal
        view
    {
        bytes memory byteHandle = bytes(handle);
        uint256 fee = feeMapping[DataTypes.Tier.Tier5];

        require(byteHandle.length >= 1, "Invalid handle length");
        if (byteHandle.length < 6) {
            fee = feeMapping[DataTypes.Tier(byteHandle.length - 1)];
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
        DataTypes.CreateProfileParams calldata params,
        DataTypes.EIP712Signature calldata sig
    ) external view {
        _requiresEnoughFee(params.handle, fee);

        // TODO re-think this internal hash function and maybe not 712?
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._CREATE_PROFILE_TYPEHASH,
                        params.to,
                        keccak256(bytes(params.handle)),
                        keccak256(bytes(params.avatar)),
                        keccak256(bytes(params.metadata)),
                        nonces[params.to]++,
                        sig.deadline
                    )
                )
            ),
            signer,
            sig
        );
    }

    /// @inheritdoc IProfileMiddleware
    function postProcess(
        uint256 fee,
        DataTypes.CreateProfileParams calldata params,
        DataTypes.EIP712Signature calldata sig
    ) external {
        // do nothing
    }
}
