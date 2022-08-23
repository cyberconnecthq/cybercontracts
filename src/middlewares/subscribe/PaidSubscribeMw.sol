// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import { ISubscribeMiddleware } from "../../interfaces/ISubscribeMiddleware.sol";
import { ICyberEngine } from "../../interfaces/ICyberEngine.sol";

import { Constants } from "../../libraries/Constants.sol";

import { FeeMw } from "../base/FeeMw.sol";
import { NFTStatusMw } from "../base/NFTStatusMw.sol";

/**
 * @title Paid Subscribe Middleware
 * @author CyberConnect
 * @notice This contract is a middleware to only allow users to subscribe when they pay a certain fee to the profile owner.
 */
contract PaidSubscribeMw is ISubscribeMiddleware, FeeMw {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                               STATES
    //////////////////////////////////////////////////////////////*/

    struct PaidSubscribeData {
        uint256 amount;
        address recipient;
        address currency;
        bool nftRequired;
        address nftAddress;
    }

    mapping(address => mapping(uint256 => PaidSubscribeData))
        internal _paidSubscribeStorage;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address treasury) FeeMw(treasury) {}

    /*//////////////////////////////////////////////////////////////
                              EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc ISubscribeMiddleware
     * @notice Stores the parameters for setting up the paid subscribe middleware, checks if the amount, recipient, and
     * currency is valid and approved, and whether a special NFT is needed to subscribe
     */
    function setSubscribeMwData(uint256 profileId, bytes calldata data)
        external
        override
        returns (bytes memory)
    {
        (
            uint256 amount,
            address recipient,
            address currency,
            bool nftRequired,
            address nftAddress
        ) = abi.decode(data, (uint256, address, address, bool, address));

        require(amount != 0, "INVALID_AMOUNT");
        require(recipient != address(0), "INVALID_ADDRESS");
        require(_currencyAllowed(currency), "CURRENCY_NOT_ALLOWED");

        _paidSubscribeStorage[msg.sender][profileId].amount = amount;
        _paidSubscribeStorage[msg.sender][profileId].recipient = recipient;
        _paidSubscribeStorage[msg.sender][profileId].currency = currency;
        _paidSubscribeStorage[msg.sender][profileId].nftRequired = nftRequired;
        _paidSubscribeStorage[msg.sender][profileId].nftAddress = nftAddress;

        return new bytes(0);
    }

    /**
     * @inheritdoc ISubscribeMiddleware
     * @notice Checks if the subscriber has the required NFT, then transfers the amount required from the subscriber to the treasury
     */
    function preProcess(
        uint256 profileId,
        address subscriber,
        address,
        bytes calldata
    ) external override {
        address currency = _paidSubscribeStorage[msg.sender][profileId]
            .currency;
        uint256 amount = _paidSubscribeStorage[msg.sender][profileId].amount;
        uint256 treasuryCollected = (amount * _treasuryFee()) /
            Constants._MAX_BPS;
        uint256 actualPaid = amount - treasuryCollected;

        if (_paidSubscribeStorage[msg.sender][profileId].nftRequired == true) {
            require(
                NFTStatusMw.checkNFT(
                    _paidSubscribeStorage[msg.sender][profileId].nftAddress,
                    subscriber
                ),
                "NO_REQUIRED_NFT"
            );
        }

        IERC20(currency).safeTransferFrom(
            subscriber,
            _paidSubscribeStorage[msg.sender][profileId].recipient,
            actualPaid
        );

        if (treasuryCollected > 0) {
            IERC20(currency).safeTransferFrom(
                subscriber,
                _treasuryAddress(),
                treasuryCollected
            );
        }
    }

    /// @inheritdoc ISubscribeMiddleware
    function postProcess(
        uint256,
        address,
        address,
        bytes calldata
    ) external {
        // do nothing
    }
}
