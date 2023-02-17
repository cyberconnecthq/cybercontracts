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

    mapping(address => mapping(uint256 => mapping(uint256 => CollectLimitedTimePaidData)))
        internal _data;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address treasury) FeeMw(treasury) {}

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
    ) external override returns (bytes memory) {
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

        _data[msg.sender][profileId][essenceId].totalSupply = totalSupply;
        _data[msg.sender][profileId][essenceId].price = price;
        _data[msg.sender][profileId][essenceId].recipient = recipient;
        _data[msg.sender][profileId][essenceId]
            .subscribeRequired = subscribeRequired;
        _data[msg.sender][profileId][essenceId]
            .profileRequired = profileRequired;
        _data[msg.sender][profileId][essenceId].startTimestamp = startTimestamp;
        _data[msg.sender][profileId][essenceId].endTimestamp = endTimestamp;
        _data[msg.sender][profileId][essenceId].currency = currency;

        emit CollectLimitedTimePaidMwSet(
            msg.sender,
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
    ) external override {
        address namespace = msg.sender;
        require(
            _data[namespace][profileId][essenceId].totalSupply >
                _data[namespace][profileId][essenceId].currentCollect,
            "COLLECT_LIMIT_EXCEEDED"
        );

        require(
            block.timestamp >=
                _data[namespace][profileId][essenceId].startTimestamp,
            "NOT_STARTED"
        );

        require(
            block.timestamp <=
                _data[namespace][profileId][essenceId].endTimestamp,
            "ENDED"
        );

        if (_data[namespace][profileId][essenceId].subscribeRequired == true) {
            require(
                _checkSubscribe(namespace, profileId, collector),
                "NOT_SUBSCRIBED"
            );
        }

        if (_data[namespace][profileId][essenceId].profileRequired == true) {
            require(_checkProfile(namespace, collector), "NOT_PROFILE_OWNER");
        }

        uint256 price = _data[namespace][profileId][essenceId].price;

        if (price > 0) {
            address currency = _data[namespace][profileId][essenceId].currency;
            IERC20(currency).safeTransferFrom(
                collector,
                _data[namespace][profileId][essenceId].recipient,
                price
            );
        }

        ++_data[namespace][profileId][essenceId].currentCollect;
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
