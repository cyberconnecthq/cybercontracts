// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

abstract contract ProfileNFTStorage {
    // constant
    uint256 internal constant _VERSION = 1;

    // storage
    address internal _nftDescriptor;
    mapping(uint256 => DataTypes.ProfileStruct) internal _profileById;
    mapping(bytes32 => uint256) internal _profileIdByHandleHash;
    mapping(uint256 => string) internal _metadataById;
    mapping(uint256 => mapping(address => bool)) internal _operatorApproval; // TODO: reconsider if useful
    mapping(address => uint256) internal _addressToPrimaryProfile;
    mapping(uint256 => DataTypes.SubscribeStruct)
        internal _subscribeByProfileId;
    mapping(address => bool) internal _subscribeMwAllowlist;
    mapping(uint256 => mapping(uint256 => DataTypes.EssenceStruct))
        internal _essenceByIdByProfileId;
    mapping(address => bool) internal _essenceMwAllowlist;
}
