// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { Address } from "openzeppelin-contracts/contracts/utils/Address.sol";

import { IProfileMiddleware } from "../../interfaces/IProfileMiddleware.sol";

import { Constants } from "../../libraries/Constants.sol";
import { DataTypes } from "../../libraries/DataTypes.sol";

import { PermissionedMw } from "../base/PermissionedMw.sol";

/**
 * @title Fee Creation Middleware
 * @author CyberConnect
 * @notice This contract is a middleware to create profile with fee.
 */
contract FeeCreationMw is IProfileMiddleware, PermissionedMw {
    event SetFeeByTier(
        address indexed namespace,
        Tier tier,
        uint256 indexed amount
    );

    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/

    struct MiddlewareData {
        address recipient;
        mapping(Tier => uint256) feeMapping;
    }

    enum Tier {
        Tier0,
        Tier1,
        Tier2,
        Tier3,
        Tier4,
        Tier5,
        Tier6
    }

    mapping(address => MiddlewareData) internal _mwDataByNamespace;

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Checks that the namespace is valid.
     */
    modifier onlyValidNamespace(address namespace) {
        address mwData = _mwDataByNamespace[namespace].recipient;
        require(mwData != address(0), "INVALID_NAMESPACE");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address engine) PermissionedMw(engine) {}

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IProfileMiddleware
    function preProcess(
        DataTypes.CreateProfileParams calldata params,
        bytes calldata data
    ) external payable override onlyValidNamespace(msg.sender) {
        MiddlewareData storage mwData = _mwDataByNamespace[msg.sender];

        _requiresValidHandle(params.handle);
        _requiresEnoughFee(msg.sender, params.handle, msg.value);

        Address.sendValue(payable(mwData.recipient), msg.value);
    }

    /// @inheritdoc IProfileMiddleware
    function postProcess(
        DataTypes.CreateProfileParams calldata params,
        bytes calldata data
    ) external override {
        // do nothing
    }

    /// @inheritdoc IProfileMiddleware
    function setProfileMwData(address namespace, bytes calldata data)
        external
        override
        onlyEngine
        returns (bytes memory)
    {
        (
            address recipient,
            uint256 tier0Fee,
            uint256 tier1Fee,
            uint256 tier2Fee,
            uint256 tier3Fee,
            uint256 tier4Fee,
            uint256 tier5Fee,
            uint256 tier6Fee
        ) = abi.decode(
                data,
                (
                    address,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256
                )
            );

        require(recipient != address(0), "INVALID_RECIPIENT");

        _setFeeByTier(namespace, Tier.Tier0, tier0Fee);
        _setFeeByTier(namespace, Tier.Tier1, tier1Fee);
        _setFeeByTier(namespace, Tier.Tier2, tier2Fee);
        _setFeeByTier(namespace, Tier.Tier3, tier3Fee);
        _setFeeByTier(namespace, Tier.Tier4, tier4Fee);
        _setFeeByTier(namespace, Tier.Tier5, tier5Fee);
        _setFeeByTier(namespace, Tier.Tier6, tier6Fee);

        _mwDataByNamespace[namespace].recipient = recipient;

        return data;
    }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the recipient address.
     *
     * @param namespace The namespace address.
     * @return address The recipient address.
     */
    function getRecipient(address namespace) external view returns (address) {
        return _mwDataByNamespace[namespace].recipient;
    }

    /**
     * @notice Gets the tier's fee.
     *
     * @param namespace The namespace address.
     * @param tier The tier.
     * @return uint256 The fee amount.
     */
    function getFeeByTier(address namespace, Tier tier)
        external
        view
        returns (uint256)
    {
        return _mwDataByNamespace[namespace].feeMapping[tier];
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _setFeeByTier(
        address namespace,
        Tier tier,
        uint256 amount
    ) internal {
        _mwDataByNamespace[namespace].feeMapping[tier] = amount;
        emit SetFeeByTier(namespace, tier, amount);
    }

    function _requiresEnoughFee(
        address namespace,
        string calldata handle,
        uint256 amount
    ) internal view {
        bytes memory byteHandle = bytes(handle);
        MiddlewareData storage mwData = _mwDataByNamespace[namespace];
        uint256 fee = 0;

        if (byteHandle.length < 7) {
            fee = mwData.feeMapping[Tier(byteHandle.length - 1)];
        } else if (byteHandle.length < 12) {
            fee = mwData.feeMapping[Tier.Tier6];
        }
        require(amount >= fee, "INSUFFICIENT_FEE");
    }

    function _requiresValidHandle(string calldata handle) internal pure {
        bytes memory byteHandle = bytes(handle);
        require(
            byteHandle.length <= Constants._MAX_HANDLE_LENGTH &&
                byteHandle.length > 0,
            "HANDLE_INVALID_LENGTH"
        );

        uint256 byteHandleLength = byteHandle.length;
        for (uint256 i = 0; i < byteHandleLength; ) {
            bytes1 b = byteHandle[i];
            require(
                (b >= "0" && b <= "9") || (b >= "a" && b <= "z") || b == "_",
                "HANDLE_INVALID_CHARACTER"
            );
            unchecked {
                ++i;
            }
        }
    }
}
