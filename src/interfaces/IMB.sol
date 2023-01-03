// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IMBEvents } from "../interfaces/IMBEvents.sol";

interface IMB is IMBEvents {
    /**
     * @notice Gets the Box address.
     *
     * @return address The Box NFT address.
     */
    function getBoxAddr() external view returns (address);

    /**
     * @notice Gets the Frame address.
     *
     * @return address The Frame NFT address.
     */
    function getFrameAddr() external view returns (address);
}
