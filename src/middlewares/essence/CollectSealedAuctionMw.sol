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
 * @title CollectAuction Middleware
 * @author 0xfd11244fEeb384AE4B1A627e94ef84358A5B4DCa
 * @notice This contract is a middleware to only allow user to collect when they are one of the top 'x' bidders if only 'x' collects are allowed.
 * the essence creator decides the number to auction. also includes the start time and end time.
 */
contract CollectSealedAuctionMw is IEssenceMiddleware, FeeMw {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                EVENT
    //////////////////////////////////////////////////////////////*/
    event CollectSealedAuctionMwSet(
        address indexed namespace,
        uint256 indexed profileId,
        uint256 indexed essenceId,
        uint256 totalSupply,
        address recipient,
        address currency,
        uint256 startTimestamp,
        uint256 endTimestamp,
        bool profileRequired,
        bool subscribeRequired
    );
    event BidPlaced(
        uint256 id,
        address bidder,
        uint256 amount,
        uint256 profileId,
        uint256 essenceId,
        address namespace
    );

    event BidRefunded(
        uint256 id,
        address refundAddress,
        uint256 amount,
        uint256 profileId,
        uint256 essenceId,
        address namespace,
        address currency
    );

    /*//////////////////////////////////////////////////////////////
                               STATES
    //////////////////////////////////////////////////////////////*/

    struct CollectSealedAuctionData {
        uint256 totalSupply;
        uint256 currentCollect;
        address currency;
        address recipient;
        uint256 startTimestamp;
        uint256 endTimestamp;
        bool profileRequired;
        bool subscribeRequired;
    }

    struct Bid {
        uint256 id;
        address bidder;
        uint256 amount;
        uint256 profileId;
        uint256 essenceId;
        bool collected;
    }

    mapping(address => mapping(uint256 => mapping(uint256 => CollectSealedAuctionData)))
        internal _data;

    mapping(address => mapping(uint256 => mapping(uint256 => Bid[])))
        internal _bidders;

    address public namespace;

    uint256 internal bidCounter;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address treasury, address _namespace) FeeMw(treasury) {
        require(_namespace != address(0), "INVALID_NAMESPACE");
        namespace = _namespace;
    }

    /*//////////////////////////////////////////////////////////////
                              EXTERNAL
    //////////////////////////////////////////////////////////////*/

    function setEssenceMwData(
        uint256 profileId,
        uint256 essenceId,
        bytes calldata data
    ) external override returns (bytes memory) {
        (
            uint256 totalSupply,
            address currency,
            address recipient,
            uint256 startTimestamp,
            uint256 endTimestamp,
            bool profileRequired,
            bool subscribeRequired
        ) = abi.decode(
                data,
                (uint256, address, address, uint256, uint256, bool, bool)
            );
        require(msg.sender == namespace, "INVALID_NAMESPACE");
        require(recipient != address(0), "INVALID_RECIPENT");
        require(totalSupply > 0, "INVALID_TOTAL_SUPPLY");
        require(endTimestamp > startTimestamp, "INVALID_TIME_RANGE");
        require(_currencyAllowed(currency), "INVALID_CURRENCY");

        _data[namespace][profileId][essenceId].totalSupply = totalSupply;
        _data[namespace][profileId][essenceId].currency = currency;
        _data[namespace][profileId][essenceId].recipient = recipient;
        _data[namespace][profileId][essenceId].startTimestamp = startTimestamp;
        _data[namespace][profileId][essenceId].endTimestamp = endTimestamp;
        _data[namespace][profileId][essenceId]
            .profileRequired = profileRequired;
        _data[namespace][profileId][essenceId]
            .subscribeRequired = subscribeRequired;

        emit CollectSealedAuctionMwSet(
            namespace,
            profileId,
            essenceId,
            totalSupply,
            recipient,
            currency,
            startTimestamp,
            endTimestamp,
            profileRequired,
            subscribeRequired
        );
        return new bytes(0);
    }

    function preProcess(
        uint256 profileId,
        uint256 essenceId,
        address collector,
        address,
        bytes calldata
    ) external override {
        require(
            _data[namespace][profileId][essenceId].totalSupply >
                _data[namespace][profileId][essenceId].currentCollect,
            "COLLECT_LIMIT_EXCEEDED"
        );

        require(
            block.timestamp >
                _data[namespace][profileId][essenceId].endTimestamp,
            "NOT_ENDED"
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

        uint256 X = _bidders[namespace][profileId][essenceId].length;
        bool flag;
        for (uint256 i = 0; i < X; i++) {
            if (
                _bidders[namespace][profileId][essenceId][i].collected ==
                false &&
                _bidders[namespace][profileId][essenceId][i].bidder == collector
            ) {
                uint256 treasuryCollected = (_bidders[namespace][profileId][
                    essenceId
                ][i].amount * _treasuryFee()) / Constants._MAX_BPS;
                uint256 actualPaid = _bidders[namespace][profileId][essenceId][
                    i
                ].amount - treasuryCollected;

                IERC20(_data[namespace][profileId][essenceId].currency)
                    .safeTransfer(
                        _data[namespace][profileId][essenceId].recipient,
                        actualPaid
                    );

                if (treasuryCollected > 0) {
                    IERC20(_data[namespace][profileId][essenceId].currency)
                        .safeTransfer(_treasuryAddress(), treasuryCollected);
                }
                flag = true;
                _bidders[namespace][profileId][essenceId][i].collected = true;
                break;
            }
        }
        require(flag, "COLLECTOR_NO_WINS");
        ++_data[namespace][profileId][essenceId].currentCollect;
    }

    function postProcess(
        uint256 profileId,
        uint256 essenceId,
        address collector,
        address essenceNFT,
        bytes calldata data
    ) external override {
        // do nothing
    }

    function placeBid(
        uint256 profileId,
        uint256 essenceId,
        uint256 amount
    ) external {
        address collector = msg.sender;
        require(amount > 0, "INVALID_AMOUNT");
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

        address currency = _data[namespace][profileId][essenceId].currency;
        IERC20(currency).safeTransferFrom(collector, address(this), amount);
        bidCounter++;

        Bid memory newBid;
        newBid.id = bidCounter;
        newBid.bidder = collector;
        newBid.essenceId = essenceId;
        newBid.profileId = profileId;
        newBid.amount = amount;

        Bid[] memory copy = _bidders[namespace][profileId][essenceId];
        uint256 X = _data[namespace][profileId][essenceId].totalSupply;
        if (copy.length < X) {
            _bidders[namespace][profileId][essenceId].push(newBid);
            emit BidPlaced(
                bidCounter,
                collector,
                amount,
                profileId,
                essenceId,
                namespace
            );
        } else {
            uint256 min;
            for (uint256 i = 1; i < copy.length; i++) {
                if (
                    _bidders[namespace][profileId][essenceId][i].amount <
                    _bidders[namespace][profileId][essenceId][min].amount
                ) {
                    min = i;
                }
            }
            require(
                newBid.amount >
                    _bidders[namespace][profileId][essenceId][min].amount,
                "NOT_TOPX_BID"
            );
            IERC20(_data[namespace][profileId][essenceId].currency)
                .safeTransfer(
                    _bidders[namespace][profileId][essenceId][min].bidder,
                    _bidders[namespace][profileId][essenceId][min].amount
                );
            _bidders[namespace][profileId][essenceId][min] = newBid;
            emit BidRefunded(
                _bidders[namespace][profileId][essenceId][min].id,
                _bidders[namespace][profileId][essenceId][min].bidder,
                _bidders[namespace][profileId][essenceId][min].amount,
                _bidders[namespace][profileId][essenceId][min].profileId,
                _bidders[namespace][profileId][essenceId][min].essenceId,
                namespace,
                currency
            );
            emit BidPlaced(
                bidCounter,
                collector,
                amount,
                profileId,
                essenceId,
                namespace
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _checkSubscribe(
        address _namespace,
        uint256 profileId,
        address collector
    ) internal view returns (bool) {
        address essenceOwnerSubscribeNFT = IProfileNFT(_namespace)
            .getSubscribeNFT(profileId);

        return (essenceOwnerSubscribeNFT != address(0) &&
            IERC721(essenceOwnerSubscribeNFT).balanceOf(collector) > 0);
    }

    function _checkProfile(address _namespace, address collector)
        internal
        view
        returns (bool)
    {
        return (IERC721(_namespace).balanceOf(collector) > 0);
    }
}
