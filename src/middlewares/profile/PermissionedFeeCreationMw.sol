// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IProfileMiddleware } from "../../interfaces/IProfileMiddleware.sol";
import { PermissionedMw } from "../base/PermissionedMw.sol";
import { FeeMw } from "../base/FeeMw.sol";
import { Constants } from "../../libraries/Constants.sol";
import { DataTypes } from "../../libraries/DataTypes.sol";
import { EIP712 } from "../../dependencies/openzeppelin/EIP712.sol";

contract PermissionedFeeCreationMw is
    IProfileMiddleware,
    EIP712,
    PermissionedMw,
    FeeMw
{
    struct MiddlewareData {
        address signer;
        address recipient;
        mapping(address => uint256) nonces;
        mapping(Tier => uint256) feeMapping;
    }

    enum Tier {
        Tier0,
        Tier1,
        Tier2,
        Tier3,
        Tier4,
        Tier5
    }

    mapping(address => MiddlewareData) public mwDataByNamespace;

    modifier onlyValidNamespace(address namespace) {
        string memory mwData = mwDataByNamespace[namespace];
        require(mwData.recipient != address(0), "INVALID_NAMESPACE");
        _;
    }

    constructor(address engine, address treasury)
        PermissionedMw(engine)
        FeeMw(treasury)
    {}

    function setProfileMwData(address namespace, bytes calldata data)
        external
        override
        onlyEngine
        returns (bytes memory)
    {
        (
            address signer,
            address recipient,
            uint256 tier0Fee,
            uint256 tier1Fee,
            uint256 tier2Fee,
            uint256 tier3Fee,
            uint256 tier4Fee,
            uint256 tier5Fee,

        ) = abi.decode(
                data,
                (
                    address,
                    address,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256
                )
            );

        require(
            signer != address(0) && recipient != address(0),
            "ZERO_INPUT_ADDRESS"
        );

        _setFeeByTier(namespace, Tier.Tier0, tier0Fee);
        _setFeeByTier(namespace, Tier.Tier1, tier1Fee);
        _setFeeByTier(namespace, Tier.Tier2, tier2Fee);
        _setFeeByTier(namespace, Tier.Tier3, tier3Fee);
        _setFeeByTier(namespace, Tier.Tier4, tier4Fee);
        _setFeeByTier(namespace, Tier.Tier5, tier5Fee);

        mwDataByNamespace[namespace].signer = signer;
        mwDataByNamespace[namespace].recipient = recipient;

        return data;
    }

    function _setFeeByTier(
        address namespace,
        Tier tier,
        uint256 amount
    ) internal {
        MiddlewareData memory mwData = mwDataByNamespace[namespace];
        uint256 preAmount = mwData.feeMapping[tier];
        mwData.feeMapping[tier] = amount;

        //emit SetFeeByTier(tier, preAmount, amount);
    }

    function _requiresEnoughFee(
        address namespace,
        string calldata handle,
        uint256 amount
    ) internal view {
        bytes memory byteHandle = bytes(handle);
        MiddlewareData memory mwData = mwDataByNamespace[namespace];
        uint256 fee = mwData.feeMapping[Tier.Tier5];

        require(byteHandle.length >= 1, "INVALID_HANDLE_LENGTH");
        if (byteHandle.length < 6) {
            fee = mwData.feeMapping[Tier(byteHandle.length - 1)];
        }
        require(amount >= fee, "INSUFFICIENT_FEE");
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

    // TODO consider move it to a spearate mw
    function _requiresValidHandle(string calldata handle) internal pure {
        bytes memory byteHandle = bytes(handle);
        require(
            byteHandle.length <= Constants._MAX_HANDLE_LENGTH &&
                byteHandle.length > 0,
            "Handle has invalid length"
        );

        uint256 byteHandleLength = byteHandle.length;
        for (uint256 i = 0; i < byteHandleLength; ) {
            bytes1 b = byteHandle[i];
            require(
                (b >= "0" && b <= "9") || (b >= "a" && b <= "z") || b == "_",
                "Handle has invalid character"
            );
            // optimation
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IProfileMiddleware
     */
    function preProcess(
        DataTypes.CreateProfileParams params,
        bytes calldata data
    ) external payable onlyValidNamespace(msg.sender) {
        address memory namespace = msg.sender;
        uint256 fee = msg.value;
        MiddlewareData memory mwData = mwDataByNamespace[namespace];

        (uint8 v, bytes32 r, bytes32 s, uint256 deadline, ) = abi.decode(
            data,
            (uint8, bytes32, bytes32, uint256)
        );

        _requiresValidHandle(params.handle);
        _requiresEnoughFee(namespace, params.handle, fee);
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._CREATE_PROFILE_TYPEHASH,
                        params.to,
                        keccak256(bytes(params.handle)),
                        keccak256(bytes(params.avatar)),
                        keccak256(bytes(params.metadata)),
                        mwData.nonces[params.to]++,
                        deadline
                    )
                )
            ),
            mwData.signer,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );

        uint256 treasuryCollected = (fee * _treasuryFee()) / Constants._MAX_BPS;
        uint256 actualCollected = fee - treasuryCollected;

        payable(mwData.recipient).transfer(actualCollected);
        if (treasuryCollected > 0) {
            payable(_treasuryAddress()).transfer(treasuryCollected);
        }
    }

    /// @inheritdoc IProfileMiddleware
    function postProcess(
        DataTypes.CreateProfileParams params,
        bytes calldata data
    ) external {
        // do nothing
    }
}
