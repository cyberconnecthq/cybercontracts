// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { ProfileNFT } from "../src/core/ProfileNFT.sol";

contract TempScript is Script {
    function run() external {
        ProfileNFT p = ProfileNFT(0x5A1Bd07533677D389EcAd9C4B1C5D8A3bce99418);
        // console.log(p.tokenURI(2));
        // console.log(p.getMetadata(2));
        console.log(p.getAvatar(2));
    }
}
