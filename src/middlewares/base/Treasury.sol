// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;
import { Owned } from "../../dependencies/solmate/Owned.sol";

import { ITreasury } from "../../interfaces/ITreasury.sol";

import { Constants } from "../../libraries/Constants.sol";

/**
 * @title Treasurt
 * @author CyberConnect
 * @notice This contract is used for treasury.
 */
contract Treasury is Owned, ITreasury {
    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/
    address internal _treasuryAddress;
    uint16 internal _treasuryFee;

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address owner,
        address treasuryAddress,
        uint16 treasuryFee
    ) {
        Owned.__Owned_Init(owner);
        _treasuryAddress = treasuryAddress;
        _treasuryFee = treasuryFee;
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the treasury address.
     *
     * @param treasuryAddress The treasury address to set.
     * @dev This function is only available to the owner.
     */
    function setTreasuryAddress(address treasuryAddress) external onlyOwner {
        _treasuryAddress = treasuryAddress;
    }

    /**
     * @notice Sets the treasury fee.
     *
     * @param treasuryFee The treasury fee to set.
     * @dev This function is only available to the owner.
     */
    function setTreasuryFee(uint16 treasuryFee) external onlyOwner {
        require(_treasuryFee <= Constants._MAX_BPS, "INVALID_TREASURY_FEE");
        _treasuryFee = treasuryFee;
    }

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ITreasury
    function getTreasuryAddress() external view override returns (address) {
        return _treasuryAddress;
    }

    /// @inheritdoc ITreasury
    function getTreasuryFee() external view override returns (uint256) {
        return _treasuryFee;
    }
}
