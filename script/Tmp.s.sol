// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { ProfileNFT } from "../src/core/ProfileNFT.sol";

contract TempScript is Script {
    function run() external {
        ProfileNFT p = ProfileNFT(0xb9FDA6C1C56dC7AC3aE787a46fD3434DA991626D);
        console.log(p.tokenURI(1));
    }
}
