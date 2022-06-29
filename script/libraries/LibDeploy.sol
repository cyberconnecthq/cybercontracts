// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;
import "forge-std/console.sol";
import { ProfileNFT } from "../../src/core/ProfileNFT.sol";
import { RolesAuthority } from "../../src/dependencies/solmate/RolesAuthority.sol";
import { Roles } from "../../src/core/Roles.sol";
import { CyberEngine } from "../../src/core/CyberEngine.sol";
import { BoxNFT } from "../../src/periphery/BoxNFT.sol";
import { SubscribeNFT } from "../../src/core/SubscribeNFT.sol";
import { Authority } from "../../src/dependencies/solmate/Auth.sol";
import { UpgradeableBeacon } from "../../src/upgradeability/UpgradeableBeacon.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Constants } from "../../src/libraries/Constants.sol";
import { ECDSA } from "../../src/dependencies/openzeppelin/ECDSA.sol";
import { DataTypes } from "../../src/libraries/DataTypes.sol";

import "forge-std/Vm.sol";

library LibDeploy {
    address private constant VM_ADDRESS =
        address(bytes20(uint160(uint256(keccak256("hevm cheat code")))));
    Vm public constant vm = Vm(VM_ADDRESS);

    // TODO: Fix engine owner, use 0 address for integration test.
    // have to be different from deployer to make tests useful
    address internal constant ENGINE_OWNER = address(0);

    address internal constant ENGINE_SIGNER =
        0x111110E8718C8DAf9262c82DC7898527AC58334a;

    // currently the engine gov is always deployer
    // address internal constant ENGINE_GOV =
    //     0x927f355117721e0E8A7b5eA20002b65B8a551890;

    function _calcContractAddress(address _origin, uint256 _nonce)
        internal
        pure
        returns (address)
    {
        bytes memory data;
        if (_nonce == 0x00)
            data = abi.encodePacked(
                bytes1(0xd6),
                bytes1(0x94),
                _origin,
                bytes1(0x80)
            );
        else if (_nonce <= 0x7f)
            data = abi.encodePacked(
                bytes1(0xd6),
                bytes1(0x94),
                _origin,
                uint8(_nonce)
            );
        else if (_nonce <= 0xff)
            data = abi.encodePacked(
                bytes1(0xd7),
                bytes1(0x94),
                _origin,
                bytes1(0x81),
                uint8(_nonce)
            );
        else if (_nonce <= 0xffff)
            data = abi.encodePacked(
                bytes1(0xd8),
                bytes1(0x94),
                _origin,
                bytes1(0x82),
                uint16(_nonce)
            );
        else if (_nonce <= 0xffffff)
            data = abi.encodePacked(
                bytes1(0xd9),
                bytes1(0x94),
                _origin,
                bytes1(0x83),
                uint24(_nonce)
            );
        else
            data = abi.encodePacked(
                bytes1(0xda),
                bytes1(0x94),
                _origin,
                bytes1(0x84),
                uint32(_nonce)
            );
        return address(uint160(uint256(keccak256(data))));
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

    function deploy(
        address deployer,
        uint256 nonce,
        // address calProfileProxy,
        string memory templateURL
    )
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

        // 0. Cal engine proxy address
        address engineAddr = _calcContractAddress(deployer, nonce + 8);

        // 1. authority
        // authority = new RolesAuthority(deployer, Authority(address(0)));
        authority = new Roles(deployer, engineAddr);
        _requiresContractAddress(deployer, nonce, address(authority));
        // 2. Deploy engine impl
        CyberEngine engineImpl = new CyberEngine();
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
                "CCP",
                // TODO: fix template
                templateURL, // to be set later in `post_deploy` script. circular dependency
                "https://image.example.com"
            );
            profileProxy = new ERC1967Proxy(address(profileImpl), initData);
            profileAddress = address(profileProxy);
            _requiresContractAddress(
                deployer,
                nonce + 3,
                address(profileProxy)
            );
            // require(calProfileProxy == address(profileProxy));
            console.log("profile proxy", address(profileProxy));
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

        // 10. set governance
        setupGovernance(CyberEngine(address(engineProxy)), deployer, authority);
        // 11. health checks
        healthCheck(
            CyberEngine(address(engineProxy)),
            deployer,
            authority,
            ProfileNFT(address(profileProxy)),
            BoxNFT(address(boxProxy))
        );
        // 12. register a profile for testing
        if (block.chainid != 1) {
            register(CyberEngine(address(engineProxy)), deployer);
        }
    }

    function healthCheck(
        CyberEngine engine,
        address deployer,
        RolesAuthority authority,
        ProfileNFT profile,
        BoxNFT box
    ) internal view {
        require(
            engine.owner() == ENGINE_OWNER,
            "CyberEngine owner is not deployer"
        );
        require(
            engine.signer() == ENGINE_SIGNER,
            "CyberEngine signer is not set correctly"
        );
        require(
            authority.canCall(
                deployer,
                address(engine),
                CyberEngine.setSigner.selector
            ),
            "CyberEngine Owner can set Signer"
        );
        require(
            authority.doesUserHaveRole(deployer, Constants._ENGINE_GOV_ROLE),
            "Governance address is not set"
        );
        require(profile.paused(), "ProfileNFT is not paused");
        require(box.paused(), "BoxNFT is not paused");

        // TODO: add all checks
    }

    function setupGovernance(
        CyberEngine engine,
        address deployer,
        RolesAuthority authority
    ) internal {
        authority.setUserRole(deployer, Constants._ENGINE_GOV_ROLE, true);

        // change user from deployer to governance
        engine.setSigner(ENGINE_SIGNER);
    }

    // utils
    bytes32 private constant _TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    // Util function
    function _hashTypedDataV4(address engineAddr, bytes32 structHash)
        private
        view
        returns (bytes32)
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                _TYPE_HASH,
                keccak256(bytes("CyberEngine")),
                keccak256(bytes("1")),
                block.chainid,
                engineAddr
            )
        );
        return ECDSA.toTypedDataHash(domainSeparator, structHash);
    }

    // for testnet, profile owner is all deployer, signer is fake
    function register(CyberEngine engine, address deployer) internal {
        string memory handle = "cyberconnect";
        // set signer
        uint256 signerPk = 1;
        address signer = vm.addr(signerPk);
        engine.setSigner(signer);

        console.log("block.timestamp", block.timestamp);
        uint256 deadline = block.timestamp + 60 * 60 * 24 * 30; // 30 days
        string
            memory avatar = "bafkreibcwcqcdf2pgwmco3pfzdpnfj3lijexzlzrbfv53sogz5uuydmvvu"; // TODO: ryan's punk
        string memory metadata = "metadata";
        bytes32 digest = _hashTypedDataV4(
            address(engine),
            keccak256(
                abi.encode(
                    Constants._REGISTER_TYPEHASH,
                    deployer,
                    keccak256(bytes(handle)),
                    keccak256(bytes(avatar)),
                    keccak256(bytes(metadata)),
                    0,
                    deadline
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, digest);

        require(engine.nonces(deployer) == 0);
        engine.register{ value: Constants._INITIAL_FEE_TIER2 }(
            DataTypes.CreateProfileParams(deployer, handle, avatar, metadata),
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
        require(engine.nonces(deployer) == 1);

        // revert signer
        engine.setSigner(ENGINE_SIGNER);
    }
}
