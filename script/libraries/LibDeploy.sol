// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;
import "forge-std/console.sol";
import { ProfileNFT } from "../../src/core/ProfileNFT.sol";
import { RolesAuthority } from "../../src/dependencies/solmate/RolesAuthority.sol";
import { EngineRoles } from "../../src/core/EngineRoles.sol";
import { CyberEngine } from "../../src/core/CyberEngine.sol";
import { CyberBoxNFT } from "../../src/periphery/CyberBoxNFT.sol";
import { SubscribeNFT } from "../../src/core/SubscribeNFT.sol";
import { Authority } from "../../src/dependencies/solmate/Auth.sol";
import { UpgradeableBeacon } from "../../src/upgradeability/UpgradeableBeacon.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Constants } from "../../src/libraries/Constants.sol";
import { DataTypes } from "../../src/libraries/DataTypes.sol";
import { Link3ProfileDescriptor } from "../../src/periphery/Link3ProfileDescriptor.sol";
import { TestLib712 } from "../../test/utils/TestLib712.sol";

import "forge-std/Vm.sol";

// TODO: deploy with salt
library LibDeploy {
    address private constant VM_ADDRESS =
        address(bytes20(uint160(uint256(keccak256("hevm cheat code")))));
    Vm public constant vm = Vm(VM_ADDRESS);

    string internal constant PROFILE_NAME = "Link3 Profile";
    string internal constant PROFILE_SYMBOL = "LINK3";
    // TODO: Fix engine owner, use 0 address for integration test.
    // have to be different from deployer to make tests useful
    address internal constant ENGINE_OWNER = address(0);
    // TODO
    address internal constant LINK3_OWNER =
        0xaB24749c622AF8FC567CA2b4d3EC53019F83dB8F;

    address internal constant ENGINE_SIGNER =
        0xaB24749c622AF8FC567CA2b4d3EC53019F83dB8F;
    bytes32 constant salt = keccak256(bytes("CyberConnect"));
    bytes32 constant link3Salt = keccak256(bytes(PROFILE_NAME));

    // currently the engine gov is always deployer
    // address internal constant ENGINE_GOV =
    //     0x927f355117721e0E8A7b5eA20002b65B8a551890;

    // all the deployed addresses, ordered by deploy order
    struct ContractAddresses {
        RolesAuthority authority;
        CyberEngine engineImpl;
        Link3ProfileDescriptor descriptorImpl;
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

    // create2
    function _computeAddress(bytes memory _byteCode, bytes32 salt)
        internal
        view
        returns (address)
    {
        bytes32 hash_ = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(_byteCode)
            )
        );
        return address(uint160(uint256(hash_)));
    }

    // create
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

        // 0. Deploy RolesAuthority
        addrs.authority = new RolesAuthority(deployer, Authority(address(0)));

        bytes memory data = abi.encodeWithSelector(
            CyberEngine.initialize.selector,
            ENGINE_OWNER,
            address(addrs.authority)
        );

        address engineImpl = _computeAddress(
            type(CyberEngine).creationCode,
            salt
        );

        address engineProxy = _computeAddress(
            abi.encodePacked(
                type(ERC1967Proxy).creationCode,
                abi.encode(engineImpl, data)
            ),
            salt
        );

        // 1. Deploy Engine Impl
        addrs.engineImpl = new CyberEngine{ salt: salt }();

        // 3. Deploy Engine Proxy
        addrs.engineProxyAddress = address(
            new ERC1967Proxy{ salt: salt }(address(addrs.engineImpl), data)
        );
        require(
            addrs.engineProxyAddress == engineProxy,
            "ENGINE_PROXY_MISMATCH"
        );

        // 4. Deploy Link3 Descriptor
        address descriptor = address(
            new Link3ProfileDescriptor{ salt: link3Salt }(LINK3_OWNER)
        );

        // 5. Set Governance Role

        addrs.authority.setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engineProxy,
            CyberEngine.allowProfileMw.selector,
            true
        );
        addrs.authority.setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engineProxy,
            CyberEngine.createNamespace.selector,
            true
        );
        addrs.authority.setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            engineProxy,
            CyberEngine.setProfileMw.selector,
            true
        );
        addrs.authority.setUserRole(deployer, Constants._ENGINE_GOV_ROLE, true);

        // 6. Deploy Link3
        CyberEngine(addrs.engineProxyAddress).createNamespace(
            DataTypes.CreateNamespaceParams(
                PROFILE_NAME,
                PROFILE_SYMBOL,
                address(0),
                address(0),
                descriptor
            )
        );

        // TODO: check address
        {
            // scope to avoid stack too deep error
            // 11. Deploy BoxNFT Impl
            addrs.boxImpl = new CyberBoxNFT{ salt: salt }();

            // 12. Deploy Proxy for BoxNFT
            addrs.boxProxy = address(
                new ERC1967Proxy{ salt: salt }(
                    address(addrs.boxImpl),
                    abi.encodeWithSelector(
                        CyberBoxNFT.initialize.selector,
                        deployer,
                        "CyberBox",
                        "CYBER_BOX"
                    )
                )
            );
        }

        // 13. set governance
        // setupGovernance(
        //     ProfileNFT(addrs.profileProxy),
        //     deployer,
        //     addrs.authority
        // );

        // 14. health checks
        // healthCheck(
        //     deployer,
        //     addrs.authority,
        //     ProfileNFT(addrs.profileProxy),
        //     CyberBoxNFT(addrs.boxProxy)
        // );

        // 15. register a profile for testing
        // if (block.chainid != 1) {
        //     register(ProfileNFT(addrs.profileProxy), deployer);
        // }
        return (
            addrs.engineProxyAddress,
            addrs.authority,
            addrs.boxProxy,
            addrs.profileProxy,
            address(addrs.descriptorProxy)
        );
    }

    function healthCheck(
        address deployer,
        RolesAuthority authority,
        ProfileNFT profile,
        CyberBoxNFT box
    ) internal view {
        require(
            profile.owner() == ENGINE_OWNER,
            "ProfileNFT owner is not deployer"
        );
        // require(
        //     profile.signer() == ENGINE_SIGNER,
        //     "ProfileNFT signer is not set correctly"
        // );
        require(
            keccak256(abi.encodePacked(profile.name())) ==
                keccak256(abi.encodePacked(PROFILE_NAME)),
            "ProfileNFT name is not set correctly"
        );
        require(
            keccak256(abi.encodePacked(profile.symbol())) ==
                keccak256(abi.encodePacked(PROFILE_SYMBOL)),
            "ProfileNFT symbol is not set correctly"
        );
        // require(
        //     authority.canCall(
        //         deployer,
        //         address(profile),
        //         ProfileNFT.setSigner.selector
        //     ),
        //     "ProfileNFT Owner can set Signer"
        // );
        require(
            authority.doesUserHaveRole(deployer, Constants._PROFILE_GOV_ROLE),
            "Governance address is not set"
        );
        require(profile.paused(), "ProfileNFT is not paused");
        require(box.paused(), "CyberBoxNFT is not paused");

        // TODO: add all checks
    }

    // function setupGovernance(
    //     ProfileNFT profile,
    //     address deployer,
    //     RolesAuthority authority
    // ) internal {
    //     authority.setUserRole(deployer, Constants._PROFILE_GOV_ROLE, true);

    //     // change user from deployer to governance
    //     profile.setSigner(ENGINE_SIGNER);
    // }

    // utils
    bytes32 private constant _TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    // for testnet, profile owner is all deployer, signer is fake
    // function register(ProfileNFT profile, address deployer) internal {
    //     string memory handle = "cyberconnect";
    //     // set signer
    //     uint256 signerPk = 1;
    //     address signer = vm.addr(signerPk);
    //     profile.setSigner(signer);
    //     require(profile.signer() == signer, "Signer is not set");

    //     console.log("block.timestamp", block.timestamp);
    //     uint256 deadline = block.timestamp + 60 * 60 * 24 * 30; // 30 days
    //     string
    //         memory avatar = "bafkreibcwcqcdf2pgwmco3pfzdpnfj3lijexzlzrbfv53sogz5uuydmvvu"; // TODO: ryan's punk
    //     string memory metadata = "metadata";
    //     bytes32 digest = TestLib712.hashTypedDataV4(
    //         address(profile),
    //         keccak256(
    //             abi.encode(
    //                 Constants._CREATE_PROFILE_TYPEHASH,
    //                 ENGINE_SIGNER,
    //                 keccak256(bytes(handle)),
    //                 keccak256(bytes(avatar)),
    //                 keccak256(bytes(metadata)),
    //                 0,
    //                 deadline
    //             )
    //         ),
    //         PROFILE_NAME,
    //         "1"
    //     );
    //     (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, digest);

    //     // use ENGINE_SIGNER instead of deployer since deployer could be a contract in anvil environment and safeMint will fail
    //     require(profile.nonces(ENGINE_SIGNER) == 0);
    //     profile.createProfile{ value: Constants._INITIAL_FEE_TIER2 }(
    //         DataTypes.CreateProfileParams(
    //             ENGINE_SIGNER,
    //             handle,
    //             avatar,
    //             metadata
    //         ),
    //         DataTypes.EIP712Signature(v, r, s, deadline)
    //     );
    //     require(profile.nonces(ENGINE_SIGNER) == 1);

    //     // revert signer
    //     profile.setSigner(ENGINE_SIGNER);
    // }
}
