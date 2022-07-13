// // SPDX-License-Identifier: GPL-3.0-or-later

// pragma solidity 0.8.14;

// import "forge-std/Script.sol";
// import { ProfileNFT } from "../../../src/core/ProfileNFT.sol";
// import { Link3ProfileDescriptor } from "../../../src/periphery/Link3ProfileDescriptor.sol";
// import { Create2Deployer } from "../../libraries/Create2Deployer.sol";
// import { LibDeploy } from "../../libraries/LibDeploy.sol";

// contract SetAnimationURL is Script {
//     address internal link3Profile = 0x98018e7Ed644c7C3aFd958F5B9040943Fed4F36B;
//     address internal link3Auth = 0x5f5c163Bb02c3A79B6CBD8c7E265D0580C073a84;
//     string internal animationUrl = "https://cyberconnect.mypinata.cloud/ipfs/bafkreig5fsr22xuogewjnoo4up46sd33d62tfdfmzt4ugaolq32ntokfjq";
//     Create2Deployer dc = Create2Deployer(address(0));

//     function run() external {
//         // make sure only on anvil
//         address deployerContract = 0x1202F1AAe12d3fcBFB9320eE2396c19f93581f41;
//         require(block.chainid == 4, "ONLY_RINKEBY");
//         vm.startBroadcast();

//         LibDeploy.deployLink3Descriptor(
//             vm,
//             deployerContract,
//             true,
//             animationUrl,
//             link3Profile,
//             link3Auth
//         );

//         vm.stopBroadcast();
//     }
// }
