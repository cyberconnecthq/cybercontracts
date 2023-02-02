// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { Address } from "openzeppelin-contracts/contracts/utils/Address.sol";
import { AggregatorV3Interface } from "chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import { IProfileMiddleware } from "../../interfaces/IProfileMiddleware.sol";

import { Constants } from "../../libraries/Constants.sol";
import { DataTypes } from "../../libraries/DataTypes.sol";

import { EIP712 } from "../../base/EIP712.sol";
import { PermissionedMw } from "../base/PermissionedMw.sol";

/**
 * @title Stable Fee Creation Middleware
 * @author CyberConnect
 * @notice This contract is a middleware to charge stable fee (USD) when creating profile.
 */
contract StableFeeCreationMw is IProfileMiddleware, EIP712, PermissionedMw {
    event SetFeeByTier(
        address indexed namespace,
        Tier tier,
        uint256 indexed amount
    );

    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/

    struct MiddlewareData {
        address signer;
        address recipient;
        mapping(address => uint256) nonces;
        mapping(Tier => uint256) feeMapping;
    }

    struct FeeData {
        address signer;
        address recipient;
        uint256 tier0Fee;
        uint256 tier1Fee;
        uint256 tier2Fee;
        uint256 tier3Fee;
        uint256 tier4Fee;
        uint256 tier5Fee;
        uint256 tier6Fee;
        uint256 tier7Fee;
    }

    enum Tier {
        Tier0,
        Tier1,
        Tier2,
        Tier3,
        Tier4,
        Tier5,
        Tier6,
        Tier7
    }

    mapping(address => MiddlewareData) internal _mwDataByNamespace;

    // Oracle address
    AggregatorV3Interface public immutable usdOracle;

    uint80 internal constant ACCEPTABLE_ROUND_TIME_DIFF_SEC = 60 * 60 * 2;

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

    constructor(address engine, address _usdOracle) PermissionedMw(engine) {
        usdOracle = AggregatorV3Interface(_usdOracle);
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IProfileMiddleware
    function preProcess(
        DataTypes.CreateProfileParams calldata params,
        bytes calldata data
    ) external payable override onlyValidNamespace(msg.sender) {
        MiddlewareData storage mwData = _mwDataByNamespace[msg.sender];

        (uint8 v, bytes32 r, bytes32 s, uint256 deadline, uint80 roundId) = abi
            .decode(data, (uint8, bytes32, bytes32, uint256, uint80));

        DataTypes.EIP712Signature memory sig;
        sig.v = v;
        sig.r = r;
        sig.s = s;
        sig.deadline = deadline;

        _requiresValidHandle(params.handle);

        if (_isValidClaimSig(params, sig, mwData)) {
            mwData.nonces[params.to]++;
            return;
        }

        _requiresValidSig(params, sig, mwData, roundId);
        require(
            _getLatestRoundTimeStamp() - _getTimeStampAt(roundId) <=
                ACCEPTABLE_ROUND_TIME_DIFF_SEC,
            "NOT_RECENT_ROUND"
        );

        uint256 feeWei = getPriceWeiAt(msg.sender, params.handle, roundId);
        require(msg.value >= feeWei, "INSUFFICIENT_FEE");
        Address.sendValue(payable(mwData.recipient), feeWei);
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
        FeeData memory d = abi.decode(data, (FeeData));

        require(
            d.signer != address(0) && d.recipient != address(0),
            "INVALID_SIGNER_OR_RECIPIENT"
        );

        _setFeeByTier(namespace, Tier.Tier0, d.tier0Fee);
        _setFeeByTier(namespace, Tier.Tier1, d.tier1Fee);
        _setFeeByTier(namespace, Tier.Tier2, d.tier2Fee);
        _setFeeByTier(namespace, Tier.Tier3, d.tier3Fee);
        _setFeeByTier(namespace, Tier.Tier4, d.tier4Fee);
        _setFeeByTier(namespace, Tier.Tier5, d.tier5Fee);
        _setFeeByTier(namespace, Tier.Tier6, d.tier6Fee);
        _setFeeByTier(namespace, Tier.Tier7, d.tier7Fee);

        _mwDataByNamespace[namespace].signer = d.signer;
        _mwDataByNamespace[namespace].recipient = d.recipient;

        return data;
    }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the signer address.
     *
     * @param namespace The namespace address.
     * @return address The signer address.
     */
    function getSigner(address namespace) external view returns (address) {
        return _mwDataByNamespace[namespace].signer;
    }

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
     * @notice Gets the nonce of the address.
     *
     * @param namespace The namespace address.
     * @param user The user address.
     * @return uint256 The nonce.
     */
    function getNonce(address namespace, address user)
        external
        view
        returns (uint256)
    {
        return _mwDataByNamespace[namespace].nonces[user];
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

    function _domainSeparatorName()
        internal
        pure
        override
        returns (string memory)
    {
        return "StableFeeCreationMw";
    }

    function _requiresValidSig(
        DataTypes.CreateProfileParams calldata params,
        DataTypes.EIP712Signature memory sig,
        MiddlewareData storage mwData,
        uint80 roundId
    ) internal {
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._CREATE_PROFILE_ORACLE_TYPEHASH,
                        params.to,
                        keccak256(bytes(params.handle)),
                        keccak256(bytes(params.avatar)),
                        keccak256(bytes(params.metadata)),
                        params.operator,
                        mwData.nonces[params.to]++,
                        sig.deadline,
                        roundId
                    )
                )
            ),
            mwData.signer,
            sig.v,
            sig.r,
            sig.s,
            sig.deadline
        );
    }

    function _isValidClaimSig(
        DataTypes.CreateProfileParams calldata params,
        DataTypes.EIP712Signature memory sig,
        MiddlewareData storage mwData
    ) internal returns (bool valid) {
        valid = _checkExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._CLAIM_PROFILE_TYPEHASH,
                        params.to,
                        keccak256(bytes(params.handle)),
                        keccak256(bytes(params.avatar)),
                        keccak256(bytes(params.metadata)),
                        params.operator,
                        mwData.nonces[params.to],
                        sig.deadline
                    )
                )
            ),
            mwData.signer,
            sig.v,
            sig.r,
            sig.s,
            sig.deadline
        );
    }

    function _checkExpectedSigner(
        bytes32 digest,
        address expectedSigner,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 deadline
    ) internal returns (bool) {
        if (deadline < block.timestamp) {
            return false;
        }

        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            return false;
        }
        address recoveredAddress = ecrecover(digest, v, r, s);
        return recoveredAddress == expectedSigner;
    }

    function _attoUSDToWei(uint256 amount, uint80 roundId)
        internal
        view
        returns (uint256)
    {
        uint256 ethPrice = uint256(_getPriceAt(roundId));
        return (amount * 1e8 * 1e18) / ethPrice;
    }

    function _getPriceAt(uint80 roundId) internal view returns (int256) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = usdOracle.getRoundData(roundId);
        return price;
    }

    function _getTimeStampAt(uint80 roundId) internal view returns (uint256) {
        // prettier-ignore
        (
            /*uint80 roundID*/,
            /*int price*/,
            /*uint startedAt*/,
            uint timeStamp,
            /*uint80 answeredInRound*/
        ) = usdOracle.getRoundData(roundId);
        return timeStamp;
    }

    function _getLatestRoundTimeStamp() internal view returns (uint256) {
        // prettier-ignore
        (
            /*uint80 roundID*/,
            /*int price*/,
            /*uint startedAt*/,
            uint timeStamp,
            /*uint80 answeredInRound*/
        ) = usdOracle.latestRoundData();
        return timeStamp;
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC VIEW
    //////////////////////////////////////////////////////////////*/

    function getPriceWeiAt(
        address namespace,
        string calldata handle,
        uint80 roundId
    ) public view returns (uint256) {
        bytes memory byteHandle = bytes(handle);
        MiddlewareData storage mwData = _mwDataByNamespace[namespace];
        uint256 feeUSD = mwData.feeMapping[Tier.Tier7];

        if (byteHandle.length < 7) {
            feeUSD = mwData.feeMapping[Tier(byteHandle.length - 1)];
        } else if (byteHandle.length < 12) {
            feeUSD = mwData.feeMapping[Tier.Tier6];
        }
        return _attoUSDToWei(feeUSD, roundId);
    }
}
