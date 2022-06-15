// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

interface ICyberEngine {
    function getSubscribeNFTTokenURI(uint256 profileId) external view returns (string memory);
}