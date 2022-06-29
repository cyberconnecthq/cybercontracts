// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;
import { DataTypes } from "../libraries/DataTypes.sol";

abstract contract CyberEngineStorage {
    // constant
    string internal constant _VERSION_STRING = "1";
    uint256 internal constant _VERSION = 1;

    // storage
    DataTypes.State internal _state;
    address public profileAddress;
    address public boxAddress;
    address public signer;
    bool public boxGiveawayEnded;
    // Shared between register and other withSig functions. Always query onchain to get the current nounce
    mapping(uint256 => DataTypes.SubscribeStruct)
        internal _subscribeByProfileId;
    mapping(address => uint256) public nonces;
    address public subscribeNFTBeacon;
    mapping(DataTypes.Tier => uint256) public feeMapping;
    mapping(address => bool) internal _subscribeMwAllowlist;
}
