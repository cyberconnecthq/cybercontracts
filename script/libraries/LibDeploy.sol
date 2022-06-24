// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;
import "forge-std/console.sol";
import { ProfileNFT } from "../../src/ProfileNFT.sol";
import { RolesAuthority } from "../../src/dependencies/solmate/RolesAuthority.sol";
import { CyberEngine } from "../../src/CyberEngine.sol";
import { BoxNFT } from "../../src/BoxNFT.sol";
import { SubscribeNFT } from "../../src/SubscribeNFT.sol";
import { Authority } from "../../src/dependencies/solmate/Auth.sol";
import { UpgradeableBeacon } from "../../src/upgradeability/UpgradeableBeacon.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Constants } from "../../src/libraries/Constants.sol";

library LibDeploy {
    // TODO: Fix engine owner, use 0 address for integration test.
    // have to be different from deployer to make tests useful
    address internal constant ENGINE_OWNER = address(0);

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
    ) internal view {
        address calc = _calcContractAddress(deployer, nonce);
        if (c != calc) {
            console.log("nonce ", nonce);
            console.log("calc ", calc);
            console.log("got ", c);
            revert("contract address mismatch");
        }
    }

    function deploy(address deployer, uint256 nonce)
        internal
        returns (
            ERC1967Proxy engineProxy,
            RolesAuthority authority,
            address boxAddress,
            address profileAddress
        )
    {
        console.log("starting nonce", nonce);
        console.log("deployer address", deployer);
        // TODO: emergency admin
        // address emergencyAdmin = address(0x1890);

        // 1. authority
        authority = new RolesAuthority(deployer, Authority(address(0)));
        _requiresContractAddress(deployer, nonce, address(authority));
        // 2. Calc CyberEngine address
        CyberEngine engineImpl = new CyberEngine();
        address engineAddr = _calcContractAddress(deployer, nonce + 8);
        _requiresContractAddress(deployer, nonce + 1, address(engineImpl));
        ERC1967Proxy profileProxy;
        {
            // scope to avoid stack too deep error
            // 3. Deploy ProfileNFT Impl
            ProfileNFT profileImpl = new ProfileNFT(address(engineAddr));
            _requiresContractAddress(deployer, nonce + 2, address(profileImpl));
            // 4. Deploy Proxy for ProfileNFT
            bytes memory initData = abi.encodeWithSelector(
                ProfileNFT.initialize.selector,
                // TODO: Naming
                "CyberConnect Profile",
                "CCP"
            );
            profileProxy = new ERC1967Proxy(address(profileImpl), initData);
            profileAddress = address(profileProxy);
            _requiresContractAddress(
                deployer,
                nonce + 3,
                address(profileProxy)
            );
        }
        ERC1967Proxy boxProxy;
        {
            // scope to avoid stack too deep error
            // 5. Deploy BoxNFT Impl
            BoxNFT boxImpl = new BoxNFT(address(engineAddr));
            _requiresContractAddress(deployer, nonce + 4, address(boxImpl));
            // 6. Deploy Proxy for BoxNFT
            bytes memory boxInitData = abi.encodeWithSelector(
                BoxNFT.initialize.selector,
                "CyberBox",
                "CYBER_BOX"
            );
            boxProxy = new ERC1967Proxy(address(boxImpl), boxInitData);
            _requiresContractAddress(deployer, nonce + 5, address(boxProxy));
            boxAddress = address(boxProxy);
        }
        // 7. Deploy SubscribeNFT Impl
        SubscribeNFT subscribeImpl = new SubscribeNFT(
            address(engineAddr),
            address(profileProxy)
        );
        _requiresContractAddress(deployer, nonce + 6, address(subscribeImpl));
        // 8. Deploy Subscribe Beacon
        UpgradeableBeacon subscribeBeacon = new UpgradeableBeacon(
            address(subscribeImpl),
            address(engineAddr)
        );
        _requiresContractAddress(deployer, nonce + 7, address(subscribeBeacon));
        // 9. Deploy Proxy for CyberEngine
        bytes memory data = abi.encodeWithSelector(
            CyberEngine.initialize.selector,
            ENGINE_OWNER, // TODO: emergency admin
            address(profileProxy),
            address(boxProxy),
            address(subscribeBeacon),
            address(authority)
        );
        engineProxy = new ERC1967Proxy(address(engineImpl), data);
        _requiresContractAddress(deployer, nonce + 8, address(engineProxy));
        // 10. setupAuth
        setupAuth(authority, address(engineProxy));
    }

    function setupAuth(RolesAuthority authority, address engine) internal {
        authority.setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            Constants._SET_SIGNER,
            true
        );
        authority.setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            Constants._SET_PROFILE_ADDR,
            true
        );
        authority.setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            Constants._SET_BOX_ADDR,
            true
        );
        authority.setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            Constants._SET_FEE_BY_TIER,
            true
        );
        authority.setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            Constants._WITHDRAW,
            true
        );
        authority.setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            Constants._SET_BOX_OPENED,
            true
        );
        authority.setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            Constants._SET_STATE,
            true
        );
        authority.setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engine,
            Constants._ALLOW_SUBSCRIBE_MW,
            true
        );
    }

    function healthCheck(CyberEngine engine, address deployer) internal view {
        require(
            engine.owner() == deployer,
            "CyberEngine owner is not deployer"
        );
    }
}
