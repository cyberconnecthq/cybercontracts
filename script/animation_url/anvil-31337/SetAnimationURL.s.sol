// // SPDX-License-Identifier: GPL-3.0-or-later

// pragma solidity 0.8.14;

// import "forge-std/Script.sol";
// import { ProfileNFT } from "../../../src/core/ProfileNFT.sol";
// import { Link3ProfileDescriptor } from "../../../src/periphery/Link3ProfileDescriptor.sol";
// import { Create2Deployer } from "../../libraries/Create2Deployer.sol";
// import { LibDeploy } from "../../libraries/LibDeploy.sol";

// contract SetAnimationURL is Script {
//     address internal link3Profile = 0xBCED30578853979f7CFDA447Ff47f63CDFA979bc;
//     string internal animationUrl =
//         "https://cyberconnect.mypinata.cloud/ipfs/bafkreifx3vcbi25afciwr55l56z45xoy7jsrqi54b2kqhd3pjb766sy5ti";
//     address internal link3Auth = 0x429562824f63BD2Cd7CBFB73Cfe264A6ff0C6e1E;
//     Create2Deployer dc = Create2Deployer(address(0));

//     function run() external {
//         // make sure only on anvil
//         address deployerContract = 0xa6e99A4ED7498b3cdDCBB61a6A607a4925Faa1B7;
//         require(block.chainid == 31337, "ONLY_ANVIL");
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
