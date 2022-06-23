// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { ICyberEngineEvents } from "./ICyberEngineEvents.sol";

interface ICyberEngine is ICyberEngineEvents {
    function subscribeNFTTokenURI(uint256 profileId)
        external
        view
        returns (string memory);

    function subscribeNFTImpl() external view returns (address);
}
