// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;
import { Owned } from "../../dependencies/solmate/Owned.sol";

import { ITreasury } from "../../interfaces/ITreasury.sol";

import { Constants } from "../../libraries/Constants.sol";

contract Treasury is Owned, ITreasury {
    address internal _treasuryAddress;
    uint16 internal _treasuryFee;

    constructor(
        address owner,
        address treasuryAddress,
        uint16 treasuryFee
    ) {
        Owned.__Owned_Init(owner);
        _treasuryAddress = treasuryAddress;
        _treasuryFee = treasuryFee;
    }

    function setTreasuryAddress(address treasuryAddress) external onlyOwner {
        _treasuryAddress = treasuryAddress;
    }

    function setTreasuryFee(uint16 treasuryFee) external onlyOwner {
        require(_treasuryFee <= Constants._MAX_BPS, "INVALID_TREASURY_FEE");
        _treasuryFee = treasuryFee;
    }

    /// @inheritdoc ITreasury
    function getTreasuryAddress() external view override returns (address) {
        return _treasuryAddress;
    }

    /// @inheritdoc ITreasury
    function getTreasuryFee() external view override returns (uint256) {
        return _treasuryFee;
    }
}
