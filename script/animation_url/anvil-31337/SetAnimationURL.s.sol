// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { ProfileNFT } from "../../../src/core/ProfileNFT.sol";
import { Link3ProfileDescriptor } from "../../../src/periphery/Link3ProfileDescriptor.sol";
import { Create2Deployer } from "../../libraries/Create2Deployer.sol";
import { LibDeploy } from "../../libraries/LibDeploy.sol";
import { DeploySetting } from "../../libraries/DeploySetting.sol";

contract SetAnimationURL is Script, DeploySetting {
    address internal link3Profile = 0x5529B9C57C9eC39d5E38AbC72e15Dd0dEEF6C37C;
    string internal animationUrl =
        "https://cyberconnect.mypinata.cloud/ipfs/bafkreibu64g4mx4iktos2iln6pyy563ttmxved2w2alw7jl4dofgcs7oge";

    function run() external {
        _setDeployParams();
        // make sure only on anvil
        address deployerContract = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
        require(block.chainid == 31337, "ONLY_ANVIL");
        vm.startBroadcast();

        LibDeploy.deployLink3Descriptor(
            vm,
            deployerContract,
            true,
            animationUrl,
            link3Profile,
            deployParams.link3Owner
        );

        vm.stopBroadcast();
    }
}
