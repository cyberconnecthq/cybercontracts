// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import { IEssenceMiddleware } from "../../interfaces/IEssenceMiddleware.sol";

import { Constants } from "../../libraries/Constants.sol";

import { FeeMw } from "../base/FeeMw.sol";
import { SubscribeStatusMw } from "../base/SubscribeStatusMw.sol";

/**
 * @title Merkle Drop Essence Middleware
 * @author CyberConnect
 * @notice This contract is a middleware to only allow users to collect an essence given the correct merkle proof
 */
contract PaidCollectMw is IEssenceMiddleware, FeeMw {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/

    struct PaidEssenceData {
        uint256 amount;
        address recipient;
        address currency;
        bool subscribeRequired;
    }

    mapping(address => mapping(uint256 => mapping(uint256 => PaidEssenceData)))
        internal _paidEssenceStorage;

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    // TODO: what do I have to have when I inherite some thing
    constructor(address treasury) FeeMw(treasury) {}

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IEssenceMiddleware
     * @notice Stores the parameters for setting up the paid essence
     */
    function setEssenceMwData(
        uint256 profileId,
        uint256 essenceId,
        bytes calldata data
    ) external override returns (bytes memory) {
        (
            uint256 amount,
            address recipient,
            address currency,
            bool subscribeRequired
        ) = abi.decode(data, (uint256, address, address, bool));

        require(amount != 0, "INVALID_AMOUNT");
        require(recipient != address(0), "INVALID_ADDRESS");

        _paidEssenceStorage[msg.sender][profileId][essenceId].amount = amount;
        _paidEssenceStorage[msg.sender][profileId][essenceId]
            .recipient = recipient;
        _paidEssenceStorage[msg.sender][profileId][essenceId]
            .currency = currency;
        _paidEssenceStorage[msg.sender][profileId][essenceId]
            .subscribeRequired = subscribeRequired;

        return new bytes(0);
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IEssenceMiddleware
     * @notice Proccess ...
     */
    function preProcess(
        uint256 profileId,
        uint256 essenceId,
        address collector,
        address,
        bytes calldata
    ) external override {
        // PaidEssenceData mwData = _paidEssenceStorage[msg.sender][profileId][
        //     essenceId
        // ];
        address currency = _paidEssenceStorage[msg.sender][profileId][essenceId]
            .currency;

        uint256 amount = _paidEssenceStorage[msg.sender][profileId][essenceId]
            .amount;

        uint256 treasuryCollected = (amount * _treasuryFee()) /
            Constants._MAX_BPS;
        uint256 actualCollected = amount - treasuryCollected;

        if (
            _paidEssenceStorage[msg.sender][profileId][essenceId]
                .subscribeRequired == true
        ) {
            SubscribeStatusMw.checkSubscribe(profileId, collector);
        }

        IERC20(currency).safeTransferFrom(
            collector,
            _paidEssenceStorage[msg.sender][profileId][essenceId].recipient,
            actualCollected
        );

        if (treasuryCollected > 0) {
            IERC20(currency).safeTransferFrom(
                collector,
                _treasuryAddress(),
                treasuryCollected
            );
        }
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
