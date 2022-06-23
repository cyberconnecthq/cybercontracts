// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { ProfileNFT } from "../src/ProfileNFT.sol";
import { RolesAuthority } from "../src/base/RolesAuthority.sol";
import { CyberEngine } from "../src/CyberEngine.sol";
import { BoxNFT } from "../src/BoxNFT.sol";
import { SubscribeNFT } from "../src/SubscribeNFT.sol";
import { Authority } from "../src/base/Auth.sol";
import { UpgradeableBeacon } from "../src/upgradeability/UpgradeableBeacon.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();

        // TODO: emergency admin
        address emergencyAdmin = address(0x1890);

        // 1. RolesAuthority
        RolesAuthority rolesAuthority = new RolesAuthority(
            address(this),
            Authority(address(0))
        );
        // 2. Deploy CyberEngine, pass this address to subscribebeacon and profile
        CyberEngine engine = new CyberEngine();
        address engineAddr = address(engine);
        // 3. Deploy ProfileNFT Impl
        ProfileNFT profileImpl = new ProfileNFT(engineAddr);
        // 4. Deploy Proxy for ProfileNFT
        bytes memory initData = abi.encodeWithSelector(
            ProfileNFT.initialize.selector,
            // TODO: Naming
            "CyberConnect Profile",
            "CCP"
        );
        ERC1967Proxy profileProxy = new ERC1967Proxy(
            address(profileImpl),
            initData
        );
        address profileAddr = address(profileProxy);
        // 5. Deploy BoxNFT Impl
        BoxNFT boxImpl = new BoxNFT(engineAddr);
        // 6. Deploy Proxy for BoxNFT
        bytes memory boxInitData = abi.encodeWithSelector(
            BoxNFT.initialize.selector,
            "CyberBox",
            "CYBER_BOX"
        );
        ERC1967Proxy boxProxy = new ERC1967Proxy(address(boxImpl), boxInitData);
        address boxAddr = address(boxProxy);
        // 7. Deploy SubscribeNFT Impl
        SubscribeNFT subscribeImpl = new SubscribeNFT(engineAddr, profileAddr);
        // 8. Deploy Subscribe Beacon
        UpgradeableBeacon subscribeBeacon = new UpgradeableBeacon(
            address(subscribeImpl),
            engineAddr
        );
        address beaconAddr = address(subscribeBeacon);
        // 9. Deploy Proxy for CyberEngine
        bytes memory data = abi.encodeWithSelector(
            CyberEngine.initialize.selector,
            emergencyAdmin,
            profileAddr,
            boxAddr,
            subscribeBeacon,
            rolesAuthority
        );

        // TODO: do a health check. subscribeNFTbeacon should have a correct ENGINE
        vm.stopBroadcast();
    }
}
