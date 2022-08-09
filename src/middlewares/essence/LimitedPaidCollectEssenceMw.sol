// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import { IEssenceMiddleware } from "../../interfaces/IEssenceMiddleware.sol";

import { Constants } from "../../libraries/Constants.sol";

import { FeeMw } from "../base/FeeMw.sol";
import { SubscribeStatusMw } from "../base/SubscribeStatusMw.sol";

/**
 * @title Limited Paid Collect Essence Middleware
 * @author CyberConnect
 * @notice This contract is a middleware to allow users to collect a certain number of essenceNFTs and they have to pay some fee to the owner.
 */
contract LimitedPaidCollectEssenceMw is IEssenceMiddleware, FeeMw {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                               STATES
    //////////////////////////////////////////////////////////////*/

    struct LimitedPaidEssenceData {
        uint256 limit;
        uint256 amount;
        address recipient;
        address currency;
        bool subscribeRequired;
        mapping(address => uint256) collectedByCollector;
    }

    mapping(address => mapping(uint256 => mapping(uint256 => LimitedPaidEssenceData)))
        internal _limitedPaidEssenceStorage;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address treasury) FeeMw(treasury) {}

    /*//////////////////////////////////////////////////////////////
                              EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IEssenceMiddleware
     * @notice Stores the parameters for setting up the limited paid essence middleware, checks if the amount, recipient, and
     * currency is valid and approved
     */
    function setEssenceMwData(
        uint256 profileId,
        uint256 essenceId,
        bytes calldata data
    ) external override returns (bytes memory) {
        (
            uint256 limit,
            uint256 amount,
            address recipient,
            address currency,
            bool subscribeRequired
        ) = abi.decode(data, (uint256, uint256, address, address, bool));

        require(amount != 0, "INVALID_AMOUNT");
        require(recipient != address(0), "INVALID_ADDRESS");
        require(_currencyAllowed(currency), "CURRENCY_NOT_ALLOWED");

        _limitedPaidEssenceStorage[msg.sender][profileId][essenceId]
            .limit = limit;
        _limitedPaidEssenceStorage[msg.sender][profileId][essenceId]
            .amount = amount;
        _limitedPaidEssenceStorage[msg.sender][profileId][essenceId]
            .recipient = recipient;
        _limitedPaidEssenceStorage[msg.sender][profileId][essenceId]
            .currency = currency;
        _limitedPaidEssenceStorage[msg.sender][profileId][essenceId]
            .subscribeRequired = subscribeRequired;

        return new bytes(0);
    }

    /**
     * @inheritdoc IEssenceMiddleware
     * @notice Determines whether the collector exceeded the collection limit and whether the collection requires prior subscription. Then processes the transaction from
     * the essence collector to the essence owner.
     */
    function preProcess(
        uint256 profileId,
        uint256 essenceId,
        address collector,
        address,
        bytes calldata
    ) external override {
        address currency = _limitedPaidEssenceStorage[msg.sender][profileId][
            essenceId
        ].currency;
        uint256 amount = _limitedPaidEssenceStorage[msg.sender][profileId][
            essenceId
        ].amount;
        uint256 treasuryCollected = (amount * _treasuryFee()) /
            Constants._MAX_BPS;
        uint256 actualPaid = amount - treasuryCollected;

        require(
            _limitedPaidEssenceStorage[msg.sender][profileId][essenceId].limit -
                _limitedPaidEssenceStorage[msg.sender][profileId][essenceId]
                    .collectedByCollector[collector] >
                0,
            "COLLECT_LIMIT_EXCEEDED"
        );

        if (
            _limitedPaidEssenceStorage[msg.sender][profileId][essenceId]
                .subscribeRequired == true
        ) {
            require(
                SubscribeStatusMw.checkSubscribe(profileId, collector),
                "NOT_SUBSCRIBED"
            );
        }

        IERC20(currency).safeTransferFrom(
            collector,
            _limitedPaidEssenceStorage[msg.sender][profileId][essenceId]
                .recipient,
            actualPaid
        );

        if (treasuryCollected > 0) {
            IERC20(currency).safeTransferFrom(
                collector,
                _treasuryAddress(),
                treasuryCollected
            );
        }

        _limitedPaidEssenceStorage[msg.sender][profileId][essenceId]
            .collectedByCollector[collector]++;
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
