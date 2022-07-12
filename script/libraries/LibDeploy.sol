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
import { Treasury } from "../../src/middlewares/base/Treasury.sol";
import { PermissionedFeeCreationMw } from "../../src/middlewares/profile/PermissionedFeeCreationMw.sol";
import "forge-std/Vm.sol";

// TODO: deploy with salt
library LibDeploy {
    address private constant VM_ADDRESS =
        address(bytes20(uint160(uint256(keccak256("hevm cheat code")))));
    Vm public constant vm = Vm(VM_ADDRESS);

    string internal constant PROFILE_NAME = "Link3";
    string internal constant PROFILE_SYMBOL = "LINK3";
    // TODO: Fix engine owner, use 0 address for integration test.
    // have to be different from deployer to make tests useful
    address internal constant ENGINE_OWNER = address(0);
    // TODO
    address internal constant LINK3_OWNER =
        0xaB24749c622AF8FC567CA2b4d3EC53019F83dB8F;

    address internal constant LINK3_SIGNER =
        0xaB24749c622AF8FC567CA2b4d3EC53019F83dB8F;
    // TODO: change for prod
    address internal constant ENGINE_TREASURY =
        0x927f355117721e0E8A7b5eA20002b65B8a551890;
    bytes32 constant salt = keccak256(bytes("CyberConnect"));
    bytes32 constant link3Salt = keccak256(bytes(PROFILE_NAME));
    address internal constant LINK3_TREASURY =
        0xaB24749c622AF8FC567CA2b4d3EC53019F83dB8F;

    // currently the engine gov is always deployer
    // TODO: change for prod
    address internal constant ENGINE_GOV =
        0x927f355117721e0E8A7b5eA20002b65B8a551890;

    // Initial States
    uint256 internal constant _INITIAL_FEE_TIER0 = 10 ether;
    uint256 internal constant _INITIAL_FEE_TIER1 = 2 ether;
    uint256 internal constant _INITIAL_FEE_TIER2 = 1 ether;
    uint256 internal constant _INITIAL_FEE_TIER3 = 0.5 ether;
    uint256 internal constant _INITIAL_FEE_TIER4 = 0.1 ether;
    uint256 internal constant _INITIAL_FEE_TIER5 = 0.01 ether;

    // all the deployed addresses, ordered by deploy order
    struct ContractAddresses {
        RolesAuthority authority;
        CyberEngine engineImpl;
        Link3ProfileDescriptor descriptorImpl;
        address descriptorProxy;
        ProfileNFT profileImpl;
        SubscribeNFT subscribeImpl;
        UpgradeableBeacon subscribeBeacon;
        UpgradeableBeacon essenceBeacon;
        address engineProxyAddress;
        CyberBoxNFT boxImpl;
        address boxProxy;
        address cyberTreasury;
        address link3Profile;
        address link3ProfileMw;
    }

    // create2
    function _computeAddress(
        bytes memory _byteCode,
        bytes32 _salt,
        address deployer
    ) internal view returns (address) {
        bytes32 hash_ = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                deployer,
                _salt,
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
            salt,
            deployer
        );

        address engineProxy = _computeAddress(
            abi.encodePacked(
                type(ERC1967Proxy).creationCode,
                abi.encode(engineImpl, data)
            ),
            salt,
            deployer
        );

        // 1. Deploy Engine Impl
        addrs.engineImpl = new CyberEngine{ salt: salt }();
        console.log(address(addrs.engineImpl));
        console.log(engineImpl);
        require(
            address(addrs.engineImpl) == engineImpl,
            "ENGINE_IMPL_MISMATCH"
        );

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
        addrs.link3Profile = CyberEngine(addrs.engineProxyAddress)
            .createNamespace(
                DataTypes.CreateNamespaceParams(
                    PROFILE_NAME,
                    PROFILE_SYMBOL,
                    address(0),
                    descriptor
                )
            );

        // 7. Deploy Protocol Treasury
        addrs.cyberTreasury = address(
            new Treasury{ salt: salt }(ENGINE_GOV, ENGINE_TREASURY, 250)
        );

        // 8. Deploy Link3 Profile Middleware
        addrs.link3ProfileMw = address(
            new PermissionedFeeCreationMw{ salt: link3Salt }(
                addrs.engineProxyAddress,
                addrs.cyberTreasury
            )
        );

        // 9. Engine Config Link3 Middleware
        CyberEngine(addrs.engineProxyAddress).allowProfileMw(
            addrs.link3ProfileMw,
            true
        );

        CyberEngine(addrs.engineProxyAddress).setProfileMw(
            addrs.link3Profile,
            addrs.link3ProfileMw,
            abi.encode(
                LINK3_SIGNER,
                LINK3_TREASURY,
                _INITIAL_FEE_TIER0,
                _INITIAL_FEE_TIER1,
                _INITIAL_FEE_TIER2,
                _INITIAL_FEE_TIER3,
                _INITIAL_FEE_TIER4,
                _INITIAL_FEE_TIER5
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
        if (block.chainid != 1) {
            register(
                ProfileNFT(addrs.link3Profile),
                deployer,
                CyberEngine(addrs.engineProxyAddress),
                PermissionedFeeCreationMw(addrs.link3ProfileMw)
            );
        }
        // TODO: fix return
        return (
            addrs.engineProxyAddress,
            addrs.authority,
            addrs.boxProxy,
            addrs.link3Profile,
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
    function register(
        ProfileNFT profile,
        address deployer,
        CyberEngine engine,
        PermissionedFeeCreationMw mw
    ) internal {
        console.log(LINK3_TREASURY.balance);
        require(
            LINK3_TREASURY.balance == 0 ether,
            "link3 treasury balance is not correct"
        );
        string memory handle = "cyberconnect";
        // set signer
        uint256 signerPk = 1;
        address signer = vm.addr(signerPk);

        // change signer to tempory signer
        engine.setProfileMw(
            address(profile),
            address(mw),
            abi.encode(
                signer,
                LINK3_TREASURY,
                _INITIAL_FEE_TIER0,
                _INITIAL_FEE_TIER1,
                _INITIAL_FEE_TIER2,
                _INITIAL_FEE_TIER3,
                _INITIAL_FEE_TIER4,
                _INITIAL_FEE_TIER5
            )
        );
        require(mw.getSigner(address(profile)) == signer, "Signer is not set");

        uint256 deadline = block.timestamp + 60 * 60 * 24 * 30; // 30 days
        string
            memory avatar = "bafkreibcwcqcdf2pgwmco3pfzdpnfj3lijexzlzrbfv53sogz5uuydmvvu"; // TODO: ryan's punk
        string memory metadata = "metadata";
        bytes32 digest;
        {
            bytes32 data = keccak256(
                abi.encode(
                    Constants._CREATE_PROFILE_TYPEHASH,
                    LINK3_SIGNER, // mint to this address
                    keccak256(bytes(handle)),
                    keccak256(bytes(avatar)),
                    keccak256(bytes(metadata)),
                    0,
                    deadline
                )
            );
            digest = TestLib712.hashTypedDataV4(
                address(mw),
                data,
                "PermissionedFeeCreationMw",
                "1"
            );
        }
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, digest);

        // use ENGINE_SIGNER instead of deployer since deployer could be a contract in anvil environment and safeMint will fail
        require(mw.getNonce(address(profile), LINK3_SIGNER) == 0);
        profile.createProfile{ value: _INITIAL_FEE_TIER2 }(
            DataTypes.CreateProfileParams(
                LINK3_SIGNER,
                handle,
                avatar,
                metadata
            ),
            abi.encode(v, r, s, deadline)
        );
        require(mw.getNonce(address(profile), LINK3_SIGNER) == 1);
        require(profile.balanceOf(LINK3_SIGNER) == 1);
        console.log(LINK3_TREASURY.balance);
        require(
            LINK3_TREASURY.balance == 0.975 ether,
            "LINK3_TREASURY_BALANCE_INCORRECT"
        );
        require(
            ENGINE_TREASURY.balance == 0.025 ether,
            "ENGINE_TREASURY_BALANCE_INCORRECT"
        );

        // revert signer
        engine.setProfileMw(
            address(profile),
            address(mw),
            abi.encode(
                LINK3_SIGNER,
                LINK3_TREASURY,
                _INITIAL_FEE_TIER0,
                _INITIAL_FEE_TIER1,
                _INITIAL_FEE_TIER2,
                _INITIAL_FEE_TIER3,
                _INITIAL_FEE_TIER4,
                _INITIAL_FEE_TIER5
            )
        );
    }
}
