// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Script.sol";
import { ProfileNFT } from "../../../src/core/ProfileNFT.sol";
import { Link3ProfileDescriptor } from "../../../src/periphery/Link3ProfileDescriptor.sol";
import { Create2Deployer } from "../../../src/deployer/Create2Deployer.sol";
import { LibDeploy } from "../../libraries/LibDeploy.sol";
import { DeploySetting } from "../../libraries/DeploySetting.sol";

contract SetAnimationURL is Script, DeploySetting {
    address internal link3Profile = 0xDeB2C11E20e9759Db94431c81cfaDd3DC392c086;
    string internal animationUrl =
        "https://cyberconnect.mypinata.cloud/ipfs/bafkreiha5zvcntatys5b4wtsgla6ch5dak2awn5wuhwx6rex5swcwzjzfm";

    function run() external {
        _setDeployParams();
        // make sure only on anvil
        require(block.chainid == 97, "ONLY_BNBT");
        vm.startBroadcast();

        LibDeploy.deployLink3Descriptor(
            vm,
            deployParams.deployerContract,
            true,
            animationUrl,
            link3Profile,
            deployParams.link3Owner
        );

        vm.stopBroadcast();
    }
}
