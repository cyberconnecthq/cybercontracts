// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

abstract contract ProfileNFTStorage {
    // constant
    uint256 internal constant _VERSION = 1;
    string internal constant _VERSION_STR = "1";

    // storage
    string internal _animationTemplate;
    string internal _imageTemplate;
    mapping(uint256 => DataTypes.ProfileStruct) internal _profileById;
    mapping(bytes32 => uint256) internal _profileIdByHandleHash;
    mapping(uint256 => string) internal _metadataById;
    mapping(uint256 => mapping(address => bool)) internal _operatorApproval; // TODO: reconsider if useful
}
