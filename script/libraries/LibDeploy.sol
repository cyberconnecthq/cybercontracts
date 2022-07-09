// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;
import "forge-std/console.sol";
import { ProfileNFT } from "../../src/core/ProfileNFT.sol";
import { RolesAuthority } from "../../src/dependencies/solmate/RolesAuthority.sol";
import { Roles } from "../../src/core/Roles.sol";
import { CyberEngine } from "../../src/core/CyberEngine.sol";
import { CyberBoxNFT } from "../../src/periphery/CyberBoxNFT.sol";
import { SubscribeNFT } from "../../src/core/SubscribeNFT.sol";
import { Authority } from "../../src/dependencies/solmate/Auth.sol";
import { UpgradeableBeacon } from "../../src/upgradeability/UpgradeableBeacon.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Constants } from "../../src/libraries/Constants.sol";
import { ECDSA } from "../../src/dependencies/openzeppelin/ECDSA.sol";
import { DataTypes } from "../../src/libraries/DataTypes.sol";
import { ProfileNFTDescriptor } from "../../src/periphery/ProfileNFTDescriptor.sol";

import "forge-std/Vm.sol";

library LibDeploy {
    address private constant VM_ADDRESS =
        address(bytes20(uint160(uint256(keccak256("hevm cheat code")))));
    Vm public constant vm = Vm(VM_ADDRESS);

    // TODO: Fix engine owner, use 0 address for integration test.
    // have to be different from deployer to make tests useful
    address internal constant ENGINE_OWNER = address(0);

    address internal constant ENGINE_SIGNER =
        0xaB24749c622AF8FC567CA2b4d3EC53019F83dB8F;

    // currently the engine gov is always deployer
    // address internal constant ENGINE_GOV =
    //     0x927f355117721e0E8A7b5eA20002b65B8a551890;

    // all the deployed addresses, ordered by deploy order
    struct ContractAddresses {
        RolesAuthority authority;
        CyberEngine engineImpl;
        ProfileNFTDescriptor descriptorImpl;
        address descriptorProxy;
        ProfileNFT profileImpl;
        address profileProxy;
        SubscribeNFT subscribeImpl;
        UpgradeableBeacon subscribeBeacon;
        UpgradeableBeacon essenceBeacon;
        address engineProxyAddress;
        CyberBoxNFT boxImpl;
        address boxProxy;
    }

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
        string memory templateURL
    )
        internal
        returns (
            address,
            RolesAuthority,
            address,
            address,
            address
        )
    {
        console.log("starting nonce", nonce);
        console.log("deployer address", deployer);
        // TODO: emergency admin
        // address emergencyAdmin = address(0x1890);

        // Define variables by using struct to avoid stack too deep error
        ContractAddresses memory addrs;

        // 0. Cal engine proxy address
        addrs.engineProxyAddress = _calcContractAddress(deployer, nonce + 9);

        // 1. authority
        // authority = new RolesAuthority(deployer, Authority(address(0)));
        addrs.authority = new Roles(deployer, addrs.engineProxyAddress);
        _requiresContractAddress(deployer, nonce, address(addrs.authority));

        // 2. Deploy engine impl
        addrs.engineImpl = new CyberEngine();
        _requiresContractAddress(
            deployer,
            nonce + 1,
            address(addrs.engineImpl)
        );

        // 3. Deploy ProfileNFTDescriptor Impl
        addrs.descriptorImpl = new ProfileNFTDescriptor(
            addrs.engineProxyAddress
        );
        _requiresContractAddress(
            deployer,
            nonce + 2,
            address(addrs.descriptorImpl)
        );
        // 4. Deploy ProfileNFTDescriptor Proxy
        addrs.descriptorProxy = address(
            new ERC1967Proxy(
                address(addrs.descriptorImpl),
                abi.encodeWithSelector(
                    ProfileNFTDescriptor.initialize.selector,
                    templateURL
                )
            )
        );
        _requiresContractAddress(
            deployer,
            nonce + 3,
            address(addrs.descriptorProxy)
        );

        {
            // scope to avoid stack too deep error
            // 5. Deploy ProfileNFT Impl
            addrs.profileImpl = new ProfileNFT(addrs.engineProxyAddress);
            _requiresContractAddress(
                deployer,
                nonce + 4,
                address(addrs.profileImpl)
            );

            // 6. Deploy Proxy for ProfileNFT
            addrs.profileProxy = address(
                new ERC1967Proxy(
                    address(addrs.profileImpl),
                    abi.encodeWithSelector(
                        ProfileNFT.initialize.selector,
                        // TODO: Naming
                        "CyberConnect Profile",
                        "CCP",
                        addrs.descriptorProxy
                    )
                )
            );
            _requiresContractAddress(
                deployer,
                nonce + 5,
                address(addrs.profileProxy)
            );
        }

        {
            // scope to avoid stack too deep error
            // 7. Deploy SubscribeNFT Impl
            addrs.subscribeImpl = new SubscribeNFT(
                address(addrs.engineProxyAddress),
                address(addrs.profileProxy)
            );
            _requiresContractAddress(
                deployer,
                nonce + 6,
                address(addrs.subscribeImpl)
            );

            // 8. Deploy Subscribe Beacon
            addrs.subscribeBeacon = new UpgradeableBeacon(
                address(addrs.subscribeImpl),
                address(addrs.engineProxyAddress)
            );
            _requiresContractAddress(
                deployer,
                nonce + 7,
                address(addrs.subscribeBeacon)
            );

            // 9. Deploy an Essence Beacon with temp subscribeIml
            // TODO: fix essence NFT
            addrs.essenceBeacon = new UpgradeableBeacon(
                address(addrs.subscribeImpl),
                address(addrs.engineProxyAddress)
            );
            _requiresContractAddress(
                deployer,
                nonce + 8,
                address(addrs.essenceBeacon)
            );
        }

        // 10. Deploy Proxy for CyberEngine
        addrs.engineProxyAddress = address(
            new ERC1967Proxy(
                address(addrs.engineImpl),
                abi.encodeWithSelector(
                    CyberEngine.initialize.selector,
                    ENGINE_OWNER, // TODO: emergency admin
                    address(addrs.profileProxy),
                    address(addrs.subscribeBeacon),
                    address(addrs.essenceBeacon),
                    address(addrs.authority)
                )
            )
        );
        _requiresContractAddress(
            deployer,
            nonce + 9,
            address(addrs.engineProxyAddress)
        );

        {
            // scope to avoid stack too deep error
            // 11. Deploy BoxNFT Impl
            addrs.boxImpl = new CyberBoxNFT();
            _requiresContractAddress(
                deployer,
                nonce + 10,
                address(addrs.boxImpl)
            );

            // 12. Deploy Proxy for BoxNFT
            addrs.boxProxy = address(
                new ERC1967Proxy(
                    address(addrs.boxImpl),
                    abi.encodeWithSelector(
                        CyberBoxNFT.initialize.selector,
                        deployer,
                        "CyberBox",
                        "CYBER_BOX"
                    )
                )
            );
            _requiresContractAddress(
                deployer,
                nonce + 11,
                address(addrs.boxProxy)
            );
        }

        // 13. set governance
        setupGovernance(
            CyberEngine(address(addrs.engineProxyAddress)),
            deployer,
            addrs.authority
        );

        // 14. health checks
        healthCheck(
            CyberEngine(address(addrs.engineProxyAddress)),
            deployer,
            addrs.authority,
            ProfileNFT(address(addrs.profileProxy)),
            CyberBoxNFT(address(addrs.boxProxy))
        );

        // 15. register a profile for testing
        if (block.chainid != 1) {
            register(CyberEngine(address(addrs.engineProxyAddress)), deployer);
        }
        return (
            addrs.engineProxyAddress,
            addrs.authority,
            addrs.boxProxy,
            addrs.profileProxy,
            address(addrs.descriptorProxy)
        );
    }

    function healthCheck(
        CyberEngine engine,
        address deployer,
        RolesAuthority authority,
        ProfileNFT profile,
        CyberBoxNFT box
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
            authority.doesUserHaveRole(deployer, Constants._PROFILE_GOV_ROLE),
            "Governance address is not set"
        );
        require(profile.paused(), "ProfileNFT is not paused");
        require(box.paused(), "CyberBoxNFT is not paused");

        // TODO: add all checks
    }

    function setupGovernance(
        CyberEngine engine,
        address deployer,
        RolesAuthority authority
    ) internal {
        authority.setUserRole(deployer, Constants._PROFILE_GOV_ROLE, true);

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
                    ENGINE_SIGNER,
                    keccak256(bytes(handle)),
                    keccak256(bytes(avatar)),
                    keccak256(bytes(metadata)),
                    0,
                    deadline
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, digest);

        // use ENGINE_SIGNER instead of deployer since deployer could be a contract in anvil environment and safeMint will fail
        require(engine.nonces(ENGINE_SIGNER) == 0);
        engine.register{ value: Constants._INITIAL_FEE_TIER2 }(
            DataTypes.CreateProfileParams(
                ENGINE_SIGNER,
                handle,
                avatar,
                metadata
            ),
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
        require(engine.nonces(ENGINE_SIGNER) == 1);

        // revert signer
        engine.setSigner(ENGINE_SIGNER);
    }
}
