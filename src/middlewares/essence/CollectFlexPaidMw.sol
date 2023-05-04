// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import { IEssenceMiddleware } from "../../interfaces/IEssenceMiddleware.sol";

import { DataTypes } from "../../libraries/DataTypes.sol";
import { Constants } from "../../libraries/Constants.sol";

import { FeeMw } from "../base/FeeMw.sol";

/**
 * @title Collect Flex Paid Middleware
 * @author CyberConnect
 * @notice This contract is a middleware to only allow users to collect when they pay a flex fee to the essence owner.
 */
contract CollectFlexPaidMw is IEssenceMiddleware, FeeMw {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyValidNamespace() {
        require(_namespace == msg.sender, "ONLY_VALID_NAMESPACE");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                EVENT
    //////////////////////////////////////////////////////////////*/

    event CollectFlexPaidMwSet(
        address indexed namespace,
        uint256 indexed profileId,
        uint256 indexed essenceId,
        address recipient
    );

    event CollectFlexPaidMwPreprocessed(
        uint256 indexed profileId,
        uint256 indexed essenceId,
        address indexed collector,
        address recipient,
        address currency,
        uint256 amount,
        string metadataId
    );

    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/

    struct MiddlewareData {
        address recipient;
    }

    mapping(uint256 => mapping(uint256 => MiddlewareData)) internal _mwStorage;
    address internal _namespace;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address treasury, address namespace) FeeMw(treasury) {
        _namespace = namespace;
    }

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEssenceMiddleware
    function setEssenceMwData(
        uint256 profileId,
        uint256 essenceId,
        bytes calldata data
    ) external override onlyValidNamespace returns (bytes memory) {
        address recipient = abi.decode(data, (address));

        require(recipient != address(0), "INVALID_RECIPIENT");

        _mwStorage[profileId][essenceId].recipient = recipient;

        emit CollectFlexPaidMwSet(_namespace, profileId, essenceId, recipient);

        return new bytes(0);
    }

    /**
     * @inheritdoc IEssenceMiddleware
     * @notice Processes the transaction from the essence collector to the essence owner.
     */
    function preProcess(
        uint256 profileId,
        uint256 essenceId,
        address collector,
        address,
        bytes calldata data
    ) external override onlyValidNamespace {
        (uint256 amount, address currency, string memory metadataId) = abi
            .decode(data, (uint256, address, string));

        require(amount > 0, "INVALID_AMOUNT");
        require(tx.origin == collector, "NOT_FROM_COLLECTOR");
        require(_currencyAllowed(currency), "CURRENCY_NOT_ALLOWED");

        uint256 treasuryCollected = (amount * _treasuryFee()) /
            Constants._MAX_BPS;

        IERC20(currency).safeTransferFrom(
            collector,
            _mwStorage[profileId][essenceId].recipient,
            amount - treasuryCollected
        );

        if (treasuryCollected > 0) {
            IERC20(currency).safeTransferFrom(
                collector,
                _treasuryAddress(),
                treasuryCollected
            );
        }

        emit CollectFlexPaidMwPreprocessed(
            profileId,
            essenceId,
            collector,
            _mwStorage[profileId][essenceId].recipient,
            currency,
            amount,
            metadataId
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
}
