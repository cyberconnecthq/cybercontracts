// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ITreasury } from "../../interfaces/ITreasury.sol";

import { Constants } from "../../libraries/Constants.sol";

contract Treasury is ITreasury {
    address internal _gov;
    address internal _treasuryAddress;
    uint16 internal _treasuryFee;

    modifier onlyGov() {
        require(_gov == msg.sender, "NON_GOV_ADDRESS");
        _;
    }

    constructor(
        address gov,
        address treasuryAddress,
        uint16 treasuryFee
    ) {
        _gov = gov;
        _treasuryAddress = treasuryAddress;
        _treasuryFee = treasuryFee;
    }

    function setGovernance(address gov) external onlyGov {
        _gov = gov;
        // TODO: emit
    }

    function setTreasuryAddress(address treasuryAddress) external onlyGov {
        _treasuryAddress = treasuryAddress;
    }

    function setTreasuryFee(uint16 treasuryFee) external onlyGov {
        require(_treasuryFee <= Constants._MAX_BPS, "INVALID_TREASURY_FEE");
        _treasuryFee = treasuryFee;
    }

    function getTreasuryAddress() external view override returns (address) {
        return _treasuryAddress;
    }

    function getTreasuryFee() external view override returns (uint16) {
        return _treasuryFee;
    }
}
