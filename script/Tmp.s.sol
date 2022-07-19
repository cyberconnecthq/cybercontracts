// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { ProfileNFT } from "../src/core/ProfileNFT.sol";
import { CyberEngine } from "../src/core/CyberEngine.sol";
import { LibDeploy } from "./libraries/LibDeploy.sol";
import { PermissionedFeeCreationMw } from "../src/middlewares/profile/PermissionedFeeCreationMw.sol";
import { DataTypes } from "../src/libraries/DataTypes.sol";

contract TempScript is Script {
    function run() external {
        vm.startBroadcast();
        address engineProxy = address(
            0xE8805326f9DA84e70c680429eD46B924b3F158F2
        );
        address link3Profile = address(
            0x8CC6517e45dB7a0803feF220D9b577326A12033f
        );
        // console.log(
        //     CyberEngine(engineProxy).getProfileMwByNamespace((link3Profile))
        // );
        // console.log(ProfileNFT(link3Profile).getAvatar(4));
        // console.log(ProfileNFT(link3Profile).getMetadata(4));
        // console.log(ProfileNFT(link3Profile).tokenURI(4));
        // console.log(ProfileNFT(link3Profile).getHandleByProfileId(4));

        bytes
            memory preData = hex"000000000000000000000000000000000000000000000000000000000000001c5c5b5105179ecdcb1d0b142a117f694344d078a71f2779ecfad7c6e299bbfe41173b321b2473962a5649e0eff1e8187275d5486c5aab29f852768d5d6c713e6d0000000000000000000000000000000000000000000000000000000062d68f86";
        (uint8 v, bytes32 r, bytes32 s, uint256 deadline) = abi.decode(
            preData,
            (uint8, bytes32, bytes32, uint256)
        );
        console.log(deadline);
        bytes memory postData = new bytes(0);
        console.log(msg.sender);

        uint256 id = ProfileNFT(link3Profile).createProfile{
            value: 0.05 ether
        }(
            DataTypes.CreateProfileParams(
                address(0xbd358966445e1089e3AdD528561719452fB78198),
                "akasuv",
                "https://lh3.googleusercontent.com/_kLUQtY2M_GaV13TSe92hYmb30IhI6SjAlCJkVrhcgPOmwdrZcuT95ohjehfCdNNYxt3Q2SHx-L7daqxYacAOR9zmS7ScBVtrp5NpA",
                "Qma7xGyDKxdhZ6CGA8iwUjGmoPzCMUCsw7Jkgzr19ozFiy",
                address(0x2A2EA826102c067ECE82Bc6E2B7cf38D7EbB1B82)
            ),
            preData,
            postData
        );
        console.log(id);
        vm.stopBroadcast();
    }
}
