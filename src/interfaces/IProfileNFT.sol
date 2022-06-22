// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface IProfileNFT {
    function createProfile(
        address to,
        DataTypes.CreateProfileParams calldata vars
    ) external returns (uint256);

    function getHandleByProfileId(uint256 profildId)
        external
        view
        returns (string memory);

    function getSubscribeAddrAndMwByProfileId(uint256 profileId)
        external
        view
        returns (address, address);

    function setSubscribeNFTAddress(uint256 profileId, address subscribeNFT)
        external;

    function setMetadata(uint256 profileId, string calldata metadata) external;

    function getOperatorApproval(uint256 profileId, address operator)
        external
        view
        returns (bool);

    function setOperatorApproval(
        uint256 profileId,
        address operator,
        bool approved
    ) external;
}
