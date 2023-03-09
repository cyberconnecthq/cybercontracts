// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { Address } from "openzeppelin-contracts/contracts/utils/Address.sol";
import { IERC721 } from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import { IEssenceMiddleware } from "../../interfaces/IEssenceMiddleware.sol";
import { IProfileNFT } from "../../interfaces/IProfileNFT.sol";

import { Constants } from "../../libraries/Constants.sol";

import { FeeMw } from "../base/FeeMw.sol";

/**
 * @title  Collect LimitedTimePaid Middleware
 * @author CyberConnect
 * @notice This contract is a middleware to only allow users to collect when they pay a certain fee to the essence owner.
 * the essence creator can choose to set rules including whether collecting this essence require profile/subscribe holder,
 * start/end time and has a total supply.
 */
contract CollectLimitedTimePaidMw is IEssenceMiddleware, FeeMw {
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

    event CollectLimitedTimePaidMwSet(
        address indexed namespace,
        uint256 indexed profileId,
        uint256 indexed essenceId,
        uint256 totalSupply,
        uint256 price,
        address recipient,
        address currency,
        uint256 endTimestamp,
        uint256 startTimestamp,
        bool profileRequired,
        bool subscribeRequired
    );

    /*//////////////////////////////////////////////////////////////
                               STATES
    //////////////////////////////////////////////////////////////*/

    struct CollectLimitedTimePaidData {
        uint256 totalSupply;
        uint256 currentCollect;
        uint256 price;
        address recipient;
        address currency;
        uint256 endTimestamp;
        uint256 startTimestamp;
        bool profileRequired;
        bool subscribeRequired;
    }

    mapping(uint256 => mapping(uint256 => CollectLimitedTimePaidData))
        internal _data;
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

    /**
     * @inheritdoc IEssenceMiddleware
     * @notice Stores the parameters for setting up the limited time paid essence middleware, checks if the recipient, total suppply
     * start/end time is valid and currency is approved.
     */
    function setEssenceMwData(
        uint256 profileId,
        uint256 essenceId,
        bytes calldata data
    ) external override onlyValidNamespace returns (bytes memory) {
        (
            uint256 totalSupply,
            uint256 price,
            address recipient,
            address currency,
            uint256 endTimestamp,
            uint256 startTimestamp,
            bool profileRequired,
            bool subscribeRequired
        ) = abi.decode(
                data,
                (
                    uint256,
                    uint256,
                    address,
                    address,
                    uint256,
                    uint256,
                    bool,
                    bool
                )
            );

        require(recipient != address(0), "INVALID_RECIPENT");
        require(totalSupply > 0, "INVALID_TOTAL_SUPPLY");
        require(endTimestamp > startTimestamp, "INVALID_TIME_RANGE");
        require(_currencyAllowed(currency), "CURRENCY_NOT_ALLOWED");

        _data[profileId][essenceId].totalSupply = totalSupply;
        _data[profileId][essenceId].price = price;
        _data[profileId][essenceId].recipient = recipient;
        _data[profileId][essenceId].subscribeRequired = subscribeRequired;
        _data[profileId][essenceId].profileRequired = profileRequired;
        _data[profileId][essenceId].startTimestamp = startTimestamp;
        _data[profileId][essenceId].endTimestamp = endTimestamp;
        _data[profileId][essenceId].currency = currency;

        emit CollectLimitedTimePaidMwSet(
            _namespace,
            profileId,
            essenceId,
            totalSupply,
            price,
            recipient,
            currency,
            endTimestamp,
            startTimestamp,
            profileRequired,
            subscribeRequired
        );

        return new bytes(0);
    }

    /**
     * @inheritdoc IEssenceMiddleware
     * @notice Determines whether the collection requires prior subscription and whether there is a limit, and processes the transaction
     * from the essence collector to the essence owner.
     */
    function preProcess(
        uint256 profileId,
        uint256 essenceId,
        address collector,
        address,
        bytes calldata
    ) external override onlyValidNamespace {
        require(tx.origin == collector, "NOT_FROM_COLLECTOR");
        require(
            _data[profileId][essenceId].totalSupply >
                _data[profileId][essenceId].currentCollect,
            "COLLECT_LIMIT_EXCEEDED"
        );

        require(
            block.timestamp >= _data[profileId][essenceId].startTimestamp,
            "NOT_STARTED"
        );

        require(
            block.timestamp <= _data[profileId][essenceId].endTimestamp,
            "ENDED"
        );

        if (_data[profileId][essenceId].subscribeRequired == true) {
            require(
                _checkSubscribe(_namespace, profileId, collector),
                "NOT_SUBSCRIBED"
            );
        }

        if (_data[profileId][essenceId].profileRequired == true) {
            require(_checkProfile(_namespace, collector), "NOT_PROFILE_OWNER");
        }

        uint256 price = _data[profileId][essenceId].price;

        if (price > 0) {
            address currency = _data[profileId][essenceId].currency;
            uint256 treasuryCollected = (price * _treasuryFee()) /
                Constants._MAX_BPS;
            uint256 actualPaid = price - treasuryCollected;

            IERC20(currency).safeTransferFrom(
                collector,
                _data[profileId][essenceId].recipient,
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

        ++_data[profileId][essenceId].currentCollect;
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
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _checkSubscribe(
        address namespace,
        uint256 profileId,
        address collector
    ) internal view returns (bool) {
        address essenceOwnerSubscribeNFT = IProfileNFT(namespace)
            .getSubscribeNFT(profileId);

        return (essenceOwnerSubscribeNFT != address(0) &&
            IERC721(essenceOwnerSubscribeNFT).balanceOf(collector) > 0);
    }

    function _checkProfile(address namespace, address collector)
        internal
        view
        returns (bool)
    {
        return (IERC721(namespace).balanceOf(collector) > 0);
    }
}
