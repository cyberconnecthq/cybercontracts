// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface IProfileNFT {
    function createProfile(DataTypes.CreateProfileParams calldata params)
        external
        returns (uint256);

    function getHandleByProfileId(uint256 profildId)
        external
        view
        returns (string memory);

    function setAnimationTemplate(string calldata template) external;

    function setImageTemplate(string calldata template) external;

    function setMetadata(uint256 profileId, string calldata metadata) external;

    function getAnimationTemplate() external view returns (string memory);

    function getImageTemplate() external view returns (string memory);

    function getMetadata(uint256 profileId)
        external
        view
        returns (string memory);

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
