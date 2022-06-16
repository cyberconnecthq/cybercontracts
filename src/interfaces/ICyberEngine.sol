// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

interface ICyberEngine {
    function subscribeNFTTokenURI(uint256 profileId)
        external
        view
        returns (string memory);

    function essenceNFTTokenURI(uint256 profileId, uint256 essenceId)
        external
        view
        returns (string memory);

    function subscribeNFTImpl() external view returns (address);
}
