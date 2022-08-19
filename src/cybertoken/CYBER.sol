// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ERC20 } from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract CYBER is ERC20, Ownable {
    // set a timer, only when the time comes, the token can be minted

    //Total supply of cyber token is 100M
    uint256 public TOTAL_SUPPLY = 100_000_000 * 10**uint256(decimals());

    constructor(address owner, address to) ERC20("CyberConnect", "CYBER") {
        transferOwnership(owner);
        _mint(to, TOTAL_SUPPLY);
    }
}
