// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ICyberBoxEvents } from "../interfaces/ICyberBoxEvents.sol";

interface ICyberBox is ICyberBoxEvents {
    /**
     * @notice Gets the signer for the CyberBox NFT.
     *
     * @return address The signer of CyberBox NFT.
     */
    function getSigner() external view returns (address);
}
