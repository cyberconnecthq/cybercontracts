// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import { ProfileNFT } from "../src/ProfileNFT.sol";
import { RolesAuthority } from "../src/dependencies/solmate/RolesAuthority.sol";
import { CyberEngine } from "../src/CyberEngine.sol";
import { BoxNFT } from "../src/BoxNFT.sol";
import { SubscribeNFT } from "../src/SubscribeNFT.sol";
import { Authority } from "../src/dependencies/solmate/Auth.sol";
import { UpgradeableBeacon } from "../src/upgradeability/UpgradeableBeacon.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployScript is Script {
    function _calcContractAddress(address _owner, uint256 _nonce)
        internal
        pure
        returns (address)
    {
        if (_nonce == 0) {
            return
                address(
                    uint160(
                        uint256(
                            keccak256(
                                abi.encodePacked(
                                    bytes1(0xd6),
                                    bytes1(0x94),
                                    _owner,
                                    bytes1(0x80)
                                )
                            )
                        )
                    )
                );
        }
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xd6),
                                bytes1(0x94),
                                _owner,
                                bytes1(uint8(_nonce))
                            )
                        )
                    )
                )
            );
    }

    function _requiresContractAddress(
        address deployer,
        uint256 nonce,
        address c
    ) internal {
        address calc = _calcContractAddress(deployer, nonce);
        if (c != calc) {
            console.log("nonce ", nonce);
            console.log("calc ", calc);
            console.log("got ", c);
            revert("contract address mismatch");
        }
    }

    function run() external {
        // HACK: https://github.com/foundry-rs/foundry/issues/2110
        uint256 nonce = vm.getNonce(msg.sender) - 1;
        console.log("starting nonce", nonce);
        console.log("deployer address", msg.sender);
        vm.startBroadcast();

        // TODO: emergency admin
        // address emergencyAdmin = address(0x1890);

        // 1. RolesAuthority
        RolesAuthority rolesAuthority = new RolesAuthority(
            address(this),
            Authority(address(0))
        );
        _requiresContractAddress(msg.sender, nonce, address(rolesAuthority));
        // 2. Calc CyberEngine address
        CyberEngine engineImpl = new CyberEngine();
        address engineAddr = _calcContractAddress(msg.sender, nonce + 8);
        _requiresContractAddress(msg.sender, nonce + 1, address(engineImpl));
        // 3. Deploy ProfileNFT Impl
        ProfileNFT profileImpl = new ProfileNFT(address(engineAddr));
        _requiresContractAddress(msg.sender, nonce + 2, address(profileImpl));
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
        _requiresContractAddress(msg.sender, nonce + 3, address(profileProxy));
        ERC1967Proxy boxProxy;
        {
            // scope to avoid stack too deep  errors
            // 5. Deploy BoxNFT Impl
            BoxNFT boxImpl = new BoxNFT(address(engineAddr));
            _requiresContractAddress(msg.sender, nonce + 4, address(boxImpl));
            // 6. Deploy Proxy for BoxNFT
            bytes memory boxInitData = abi.encodeWithSelector(
                BoxNFT.initialize.selector,
                "CyberBox",
                "CYBER_BOX"
            );
            boxProxy = new ERC1967Proxy(address(boxImpl), boxInitData);
            _requiresContractAddress(msg.sender, nonce + 5, address(boxProxy));
        }
        // 7. Deploy SubscribeNFT Impl
        SubscribeNFT subscribeImpl = new SubscribeNFT(
            address(engineAddr),
            address(profileProxy)
        );
        _requiresContractAddress(msg.sender, nonce + 6, address(subscribeImpl));
        // 8. Deploy Subscribe Beacon
        UpgradeableBeacon subscribeBeacon = new UpgradeableBeacon(
            address(subscribeImpl),
            address(engineAddr)
        );
        _requiresContractAddress(
            msg.sender,
            nonce + 7,
            address(subscribeBeacon)
        );
        // 9. Deploy Proxy for CyberEngine
        bytes memory data = abi.encodeWithSelector(
            CyberEngine.initialize.selector,
            msg.sender, // TODO: emergency admin
            address(profileProxy),
            address(boxProxy),
            address(subscribeBeacon),
            address(rolesAuthority)
        );
        ERC1967Proxy engineProxy = new ERC1967Proxy(address(engineImpl), data);
        _requiresContractAddress(msg.sender, nonce + 8, address(engineProxy));

        // TODO: set correct role capacity
        // TODO: do a health check. verify everything
        vm.stopBroadcast();
    }
}
