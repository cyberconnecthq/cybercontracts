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

    mapping(uint256 => Bid) internal _allBids;

    address public namespace;

    uint256 internal bidCounter;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address treasury) FeeMw(treasury) {}

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
        require(recipient != address(0), "INVALID_RECIPENT");
        require(totalSupply > 0, "INVALID_TOTAL_SUPPLY");
        require(endTimestamp > startTimestamp, "INVALID_TIME_RANGE");
        require(_currencyAllowed(currency), "INVALID_CURRENCY");
        if (namespace == address(0)) {
            namespace = msg.sender;
        }

        _data[msg.sender][profileId][essenceId].totalSupply = totalSupply;
        _data[msg.sender][profileId][essenceId].currency = currency;
        _data[msg.sender][profileId][essenceId].recipient = recipient;
        _data[msg.sender][profileId][essenceId].startTimestamp = startTimestamp;
        _data[msg.sender][profileId][essenceId].endTimestamp = endTimestamp;
        _data[msg.sender][profileId][essenceId]
            .profileRequired = profileRequired;
        _data[msg.sender][profileId][essenceId]
            .subscribeRequired = subscribeRequired;
        // yet to set the emits
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

        uint256[] memory topBids = findTopXBidders(
            _data[namespace][profileId][essenceId].totalSupply,
            profileId,
            essenceId
        );
        bool flag;
        for (uint256 i = 0; i < topBids.length; i++) {
            if (
                _allBids[topBids[i]].collected == false &&
                _allBids[topBids[i]].bidder == collector
            ) {
                // uint bidAmt=_allBids[topBids[i]].amount;
                if (_allBids[topBids[i]].amount > 0) {
                    // address currency = _data[namespace][profileId][essenceId].currency;
                    uint256 treasuryCollected = (_allBids[topBids[i]].amount *
                        _treasuryFee()) / Constants._MAX_BPS;
                    uint256 actualPaid = _allBids[topBids[i]].amount -
                        treasuryCollected;

                    // IERC20(_data[namespace][profileId][essenceId].currency).safeTransferFrom(
                    //     address(this),
                    //     _data[namespace][profileId][essenceId].recipient,
                    //     actualPaid
                    // );
                    IERC20(_data[namespace][profileId][essenceId].currency)
                        .safeTransfer(
                            _data[namespace][profileId][essenceId].recipient,
                            actualPaid
                        );

                    if (treasuryCollected > 0) {
                        IERC20(_data[namespace][profileId][essenceId].currency)
                            .safeTransfer(
                                _treasuryAddress(),
                                treasuryCollected
                            );
                    }
                    flag = true;
                    _allBids[topBids[i]].collected = true;
                    break;
                }
            }
        }
        require(flag, "Collector_No_Wins");

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
        _allBids[bidCounter] = newBid;
        _bidders[namespace][profileId][essenceId].push(newBid);

        emit BidPlaced(
            bidCounter,
            collector,
            amount,
            profileId,
            essenceId,
            namespace
        );
    }

    function withdraw(uint256 profileId, uint256 essenceId) public {
        require(
            0 < _data[namespace][profileId][essenceId].totalSupply,
            "Invalid Profile/Essence"
        );
        require(
            block.timestamp >
                _data[namespace][profileId][essenceId].endTimestamp,
            "NOT_ENDED"
        );
        uint256[] memory topBids = findTopXBidders(
            _data[namespace][profileId][essenceId].totalSupply,
            profileId,
            essenceId
        );
        // uint [] allUserBids;

        // uint countMyBids;

        // for(uint i=0;i<_bidders[namespace][profileId][essenceId].length;i++){
        //     if(_bidders[namespace][profileId][essenceId][i].bidder==msg.sender){
        //         countMyBids++;
        //     }
        // }

        // uint[] memory myRefundableBids= new uint[](countMyBids);
        // uint refundableBidsNumber;
        bool canWithdraw;
        for (
            uint256 i = 0;
            i < _bidders[namespace][profileId][essenceId].length;
            i++
        ) {
            if (
                _bidders[namespace][profileId][essenceId][i].bidder ==
                msg.sender &&
                _bidders[namespace][profileId][essenceId][i].collected == false
            ) {
                // _bidders[namespace][profileId][essenceId][i].id
                bool flag;
                for (uint256 j = 0; j < topBids.length; j++) {
                    if (
                        _bidders[namespace][profileId][essenceId][i].id ==
                        topBids[j]
                    ) {
                        flag = true;
                    }
                }
                if (!flag) {
                    canWithdraw = true;
                    IERC20(_data[namespace][profileId][essenceId].currency)
                        .safeTransfer(
                            msg.sender,
                            _bidders[namespace][profileId][essenceId][i].amount
                        );
                    _bidders[namespace][profileId][essenceId][i]
                        .collected = true;
                }
            }
        }
        require(canWithdraw, "CANNOT_WITHDRAW");
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

    // function findBidderNonCollectedBid(address _bidder,uint _profileId,uint _essenceId) internal view {

    // }

    function findTopXBidders(
        uint256 x,
        uint256 _profileId,
        uint256 _essenceId
    ) internal returns (uint256[] memory) {
        uint256 n = _bidders[namespace][_profileId][_essenceId].length;
        require(n > 0, "NO_BIDS");
        if (n < x) {
            x = n;
        }
        uint256[] memory topX = new uint256[](x);
        uint256 counter = 0;
        for (uint256 i = 0; i < x; i++) {
            for (uint256 j = 0; j < n - 1; j++) {
                if (
                    _bidders[namespace][_profileId][_essenceId][j].amount >
                    _bidders[namespace][_profileId][_essenceId][j + 1].amount
                ) {
                    Bid memory copyBid = _bidders[namespace][_profileId][
                        _essenceId
                    ][j + 1];
                    _bidders[namespace][_profileId][_essenceId][
                        j + 1
                    ] = _bidders[namespace][_profileId][_essenceId][j];
                    _bidders[namespace][_profileId][_essenceId][j] = copyBid;
                }
            }
            topX[counter] = _bidders[namespace][_profileId][_essenceId][
                n - counter - 1
            ].id;
            counter++;
        }
        return topX;
    }
}
