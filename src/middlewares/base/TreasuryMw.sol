// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ITreasury } from "../../interfaces/ITreasury.sol";
import { Constants } from "../../libraries/Constants.sol";

contract Treasury is ITreasury {
    address public gov;
    address public treasuryAddress;
    uint16 public treasuryFee;

    modifier onlyGov() {
        require(gov == msg.sender, "NON_GOV_ADDRESS");
        _;
    }

    constructor(
        address _gov,
        address _treasuryAddress,
        uint16 _treasuryFee
    ) {
        setGovernance(_gov);
        setTreasuryAddress(_treasuryAddress);
        setTreasuryFee(_treasuryFee);
    }

    function setGovernance(address _gov) public onlyGov {
        gov = _gov;
    }

    function setTreasuryAddress(address _treasuryAddress) public onlyGov {
        treasuryAddress = _treasuryAddress;
    }

    function setTreasuryFee(uint16 _treasuryFee) public onlyGov {
        require(_treasuryFee <= Constants._MAX_BPS, "INVALID_TREASURY_FEE");
        treasuryFee = _treasuryFee;
    }

    function getTreasuryAddress() external view override returns (address) {
        return treasuryAddress;
    }

    function getTreasuryFee() external view override returns (uint16) {
        return treasuryFee;
    }
}
