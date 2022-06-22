// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface IProfileNFT {
    function createProfile(address to, DataTypes.ProfileStruct calldata vars)
        external
        returns (uint256);

    function getHandleByProfileId(uint256 profildId)
        external
        view
        returns (string memory);

    function getSubscribeNFTAddressByProfileId(uint256 profileId)
        external
        view
        returns (address);

    function setSubscribeNFTAddress(uint256 profileId, address subscribeNFT)
        external;
}
