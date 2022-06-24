// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { ICyberEngineEvents } from "./ICyberEngineEvents.sol";

interface ICyberEngine is ICyberEngineEvents {
    function getSubscribeNFTTokenURI(uint256 profileId)
        external
        view
        returns (string memory);

    function getSubscribeNFT(uint256 profileId) external view returns (address);
}
