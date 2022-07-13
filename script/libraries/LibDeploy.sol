// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;
import "forge-std/console.sol";
import { ProfileNFT } from "../../src/core/ProfileNFT.sol";
import { RolesAuthority } from "../../src/dependencies/solmate/RolesAuthority.sol";
import { CyberEngine } from "../../src/core/CyberEngine.sol";
import { CyberBoxNFT } from "../../src/periphery/CyberBoxNFT.sol";
import { SubscribeNFT } from "../../src/core/SubscribeNFT.sol";
import { EssenceNFT } from "../../src/core/EssenceNFT.sol";
import { Authority } from "../../src/dependencies/solmate/Auth.sol";
import { UpgradeableBeacon } from "../../src/upgradeability/UpgradeableBeacon.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Constants } from "../../src/libraries/Constants.sol";
import { DataTypes } from "../../src/libraries/DataTypes.sol";
import { Link3ProfileDescriptor } from "../../src/periphery/Link3ProfileDescriptor.sol";
import { TestLib712 } from "../../test/utils/TestLib712.sol";
import { Treasury } from "../../src/middlewares/base/Treasury.sol";
import { PermissionedFeeCreationMw } from "../../src/middlewares/profile/PermissionedFeeCreationMw.sol";
import { Create2Deployer } from "./Create2Deployer.sol";
import { EssenceNFTFactory } from "../../src/factory/EssenceNFTFactory.sol";
import { SubscribeNFTFactory } from "../../src/factory/SubscribeNFTFactory.sol";
import { ProfileNFTFactory } from "../../src/factory/ProfileNFTFactory.sol";
import { LibString } from "../../src/libraries/LibString.sol";

import "forge-std/Vm.sol";

// TODO: deploy with salt
library LibDeploy {
    string internal constant PROFILE_NAME = "Link3";
    string internal constant PROFILE_SYMBOL = "LINK3";
    // TODO: Fix engine owner, use 0 address for integration test.
    // have to be different from deployer to make tests useful
    address internal constant ENGINE_OWNER = address(0);
    // TODO: change for prod. need access
    address internal constant LINK3_OWNER =
        0x927f355117721e0E8A7b5eA20002b65B8a551890;

    address internal constant LINK3_SIGNER =
        0xaB24749c622AF8FC567CA2b4d3EC53019F83dB8F;
    // TODO: change for prod
    address internal constant ENGINE_TREASURY =
        0x1890a1625d837A809b0e77EdE1a999a161df085d;
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

    string internal constant OUTPUT_FILE = "docs/deploy/";

    function _fileName() internal view returns (string memory) {
        uint256 chainId = block.chainid;
        string memory chainName;
        if (chainId == 1) chainName = "mainnet";
        else if (chainId == 3) chainName = "ropsten";
        else if (chainId == 4) chainName = "rinkeby";
        else if (chainId == 5) chainName = "goerli";
        else if (chainId == 42) chainName = "kovan";
        else if (chainId == 31337) chainName = "anvil";
        else chainName = "unknown";
        return
            string(
                abi.encodePacked(
                    OUTPUT_FILE,
                    string(
                        abi.encodePacked(
                            chainName,
                            "-",
                            LibString.toString(chainId)
                        )
                    ),
                    "/contract"
                )
            );
    }

    function _fileNameMd() internal view returns (string memory) {
        return string(abi.encodePacked(_fileName(), ".md"));
    }

    function _fileNameJson() internal view returns (string memory) {
        return string(abi.encodePacked(_fileName(), ".json"));
    }

    function _prepareToWrite(Vm vm) internal {
        vm.removeFile(_fileNameMd());
        vm.removeFile(_fileNameJson());
    }

    function _writeText(
        Vm vm,
        string memory fileName,
        string memory text
    ) internal {
        vm.writeLine(fileName, text);
    }

    function _writeHelper(
        Vm vm,
        string memory name,
        address addr,
        bool lastLine
    ) internal {
        _writeText(
            vm,
            _fileNameMd(),
            string(
                abi.encodePacked(
                    "|",
                    name,
                    "|",
                    LibString.toHexString(addr),
                    "|"
                )
            )
        );
        _writeText(
            vm,
            _fileNameJson(),
            string(
                abi.encodePacked(
                    '  "',
                    name,
                    '": "',
                    LibString.toHexString(addr),
                    lastLine ? '"' : '",'
                )
            )
        );
    }

    function _write(
        Vm vm,
        string memory name,
        address addr
    ) internal {
        _writeHelper(vm, name, addr, false);
    }

    function _writeLastLine(
        Vm vm,
        string memory name,
        address addr
    ) internal {
        _writeHelper(vm, name, addr, true);
    }

    // all the deployed addresses, ordered by deploy order
    struct ContractAddresses {
        address authority;
        address engineImpl;
        address descriptorImpl;
        address descriptorProxy;
        address profileImpl;
        address subscribeImpl;
        address subscribeBeacon;
        address essenceBeacon;
        address engineProxyAddress;
        address boxImpl;
        address boxProxy;
        address cyberTreasury;
        address link3Profile;
        address link3ProfileMw;
        address calcEngineImpl;
        address calcEngineProxy;
        address link3Authority;
    }

    // create2
    function _computeAddress(
        bytes memory _byteCode,
        bytes32 _salt,
        address deployer
    ) internal pure returns (address) {
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

    // for testing
    function deployInTest(
        Vm vm,
        address deployer,
        uint256 nonce
    )
        internal
        returns (
            address,
            address,
            address,
            address,
            address
        )
    {
        return deploy(vm, deployer, nonce, address(0), false);
    }

    function deploy(
        Vm vm,
        address deployer,
        uint256 nonce,
        address _deployerContract,
        bool writeFile
    )
        internal
        returns (
            address,
            address,
            address,
            address,
            address
        )
    {
        if (writeFile) {
            _prepareToWrite(vm);
            _writeText(vm, _fileNameJson(), "{");
            _writeText(vm, _fileNameMd(), "|Contract|Address|");
            _writeText(vm, _fileNameMd(), "|-|-|");
        }
        console.log("starting nonce", nonce);
        console.log("deployer address", deployer);
        // TODO: emergency admin
        // address emergencyAdmin = address(0x1890);

        // Define variables by using struct to avoid stack too deep error
        ContractAddresses memory addrs;
        Create2Deployer dc;
        if (_deployerContract == address(0)) {
            console.log(
                "=====================deploying deployer contract================="
            );
            dc = new Create2Deployer(); // for running test
            if (writeFile) {
                _write(vm, "Create2Deployer", address(dc));
            }
        } else {
            dc = Create2Deployer(_deployerContract); // for deployment
        }

        // 0. Deploy RolesAuthority
        addrs.authority = dc.deploy(
            abi.encodePacked(
                type(RolesAuthority).creationCode,
                abi.encode(deployer, Authority(address(0))) // use deployer here so that 1. in test, deployer is Test contract 2. in deployment, deployer is the msg.sender
            ),
            salt
        );
        if (writeFile) {
            _write(vm, "RolesAuthority", addrs.authority);
        }

        bytes memory data = abi.encodeWithSelector(
            CyberEngine.initialize.selector,
            ENGINE_OWNER,
            address(addrs.authority)
        );

        addrs.calcEngineImpl = _computeAddress(
            type(CyberEngine).creationCode,
            salt,
            address(dc)
        );

        addrs.calcEngineProxy = _computeAddress(
            abi.encodePacked(
                type(ERC1967Proxy).creationCode,
                abi.encode(addrs.calcEngineImpl, data)
            ),
            salt,
            address(dc)
        );

        // 1. Deploy Engine Impl
        addrs.engineImpl = dc.deploy(type(CyberEngine).creationCode, salt);
        if (writeFile) {
            _write(vm, "EngineImpl", addrs.engineImpl);
        }

        require(
            address(addrs.engineImpl) == addrs.calcEngineImpl,
            "ENGINE_IMPL_MISMATCH"
        );

        // 2. Deploy Engine Proxy
        addrs.engineProxyAddress = dc.deploy(
            abi.encodePacked(
                type(ERC1967Proxy).creationCode,
                abi.encode(addrs.calcEngineImpl, data)
            ),
            salt
        );
        if (writeFile) {
            _write(vm, "EngineProxy", addrs.engineProxyAddress);
        }

        require(
            addrs.engineProxyAddress == addrs.calcEngineProxy,
            "ENGINE_PROXY_MISMATCH"
        );

        // 3. Deploy Link3 Descriptor Impl
        addrs.descriptorImpl = dc.deploy(
            abi.encodePacked(
                type(Link3ProfileDescriptor).creationCode,
                abi.encode(LINK3_OWNER)
            ),
            salt
        );
        // addrs.descriptorImpl = address(
        //     new Link3ProfileDescriptor{ salt: link3Salt }(LINK3_OWNER)
        // );

        // 4. Deploy Link3 Descriptor Proxy
        addrs.descriptorProxy = dc.deploy(
            abi.encodePacked(
                type(ERC1967Proxy).creationCode,
                abi.encode(
                    addrs.descriptorImpl,
                    abi.encodeWithSelector(
                        Link3ProfileDescriptor.initialize.selector,
                        ""
                    )
                )
            ),
            salt
        );

        // 5. Set Governance Role

        RolesAuthority(addrs.authority).setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            addrs.engineProxyAddress,
            CyberEngine.allowProfileMw.selector,
            true
        );
        RolesAuthority(addrs.authority).setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            addrs.engineProxyAddress,
            CyberEngine.createNamespace.selector,
            true
        );
        RolesAuthority(addrs.authority).setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            addrs.engineProxyAddress,
            CyberEngine.setProfileMw.selector,
            true
        );
        RolesAuthority(addrs.authority).setUserRole(
            deployer, //use deployer here so that 1. in test, deployer is Test contract 2. in deployment, deployer is the msg.sender
            Constants._ENGINE_GOV_ROLE,
            true
        );

        // 6. Deploy Link3
        (addrs.link3Profile, addrs.link3Authority) = deployLink3(
            addrs.engineProxyAddress,
            vm,
            writeFile
        );
        if (writeFile) {
            _write(vm, "Link3 Profile", addrs.link3Profile);
            _write(vm, "Link3 Authority", addrs.link3Authority);
        }

        // 7. Deploy Protocol Treasury
        addrs.cyberTreasury = dc.deploy(
            abi.encodePacked(
                type(Treasury).creationCode,
                abi.encode(ENGINE_GOV, ENGINE_TREASURY, 250)
            ),
            salt
        );
        if (writeFile) {
            _write(vm, "CyberConnect Treasury", addrs.cyberTreasury);
        }
        // addrs.cyberTreasury = address(
        //     new Treasury{ salt: salt }(ENGINE_GOV, ENGINE_TREASURY, 250)
        // );

        // 8. Deploy Link3 Profile Middleware
        addrs.link3ProfileMw = dc.deploy(
            abi.encodePacked(
                type(PermissionedFeeCreationMw).creationCode,
                abi.encode(addrs.engineProxyAddress, addrs.cyberTreasury)
            ),
            salt
        );

        if (writeFile) {
            _write(
                vm,
                "Link3 Profile MW (PermissionedFeeCreationMw)",
                addrs.link3ProfileMw
            );
        }
        // addrs.link3ProfileMw = address(
        //     new PermissionedFeeCreationMw{ salt: link3Salt }(
        //         addrs.engineProxyAddress,
        //         addrs.cyberTreasury
        //     )
        // );

        // 9. Engine Allow Middleware
        CyberEngine(addrs.engineProxyAddress).allowProfileMw(
            addrs.link3ProfileMw,
            true
        );

        // 1o. Engine Config Link3 Profile Middleware
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
            addrs.boxImpl = dc.deploy(type(CyberBoxNFT).creationCode, salt);
            if (writeFile) {
                _write(vm, "CyberBoxNFT (Impl)", addrs.boxImpl);
            }

            // 12. Deploy Proxy for BoxNFT
            bytes memory _data = abi.encodeWithSelector(
                CyberBoxNFT.initialize.selector,
                ENGINE_GOV,
                "CyberBox",
                "CYBER_BOX"
            );
            addrs.boxProxy = dc.deploy(
                abi.encodePacked(
                    type(ERC1967Proxy).creationCode,
                    abi.encode(addrs.boxImpl, _data)
                ),
                salt
            );
            if (writeFile) {
                _write(vm, "CyberBoxNFT (Proxy)", addrs.boxProxy);
            }
        }

        // 15. register a profile for testing
        if (block.chainid != 1) {
            register(
                vm,
                ProfileNFT(addrs.link3Profile),
                CyberEngine(addrs.engineProxyAddress),
                PermissionedFeeCreationMw(addrs.link3ProfileMw)
            );
        }

        if (writeFile) {
            _writeText(vm, _fileNameJson(), "}");
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

    // function healthCheck(
    //     address deployer,
    //     RolesAuthority authority,
    //     ProfileNFT profile,
    //     CyberBoxNFT box
    // ) internal view {
    //     require(
    //         profile.owner() == ENGINE_OWNER,
    //         "ProfileNFT owner is not deployer"
    //     );
    //     // require(
    //     //     profile.signer() == ENGINE_SIGNER,
    //     //     "ProfileNFT signer is not set correctly"
    //     // );
    //     require(
    //         keccak256(abi.encodePacked(profile.name())) ==
    //             keccak256(abi.encodePacked(PROFILE_NAME)),
    //         "ProfileNFT name is not set correctly"
    //     );
    //     require(
    //         keccak256(abi.encodePacked(profile.symbol())) ==
    //             keccak256(abi.encodePacked(PROFILE_SYMBOL)),
    //         "ProfileNFT symbol is not set correctly"
    //     );
    //     // require(
    //     //     authority.canCall(
    //     //         deployer,
    //     //         address(profile),
    //     //         ProfileNFT.setSigner.selector
    //     //     ),
    //     //     "ProfileNFT Owner can set Signer"
    //     // );
    //     require(
    //         authority.doesUserHaveRole(deployer, Constants._PROFILE_GOV_ROLE),
    //         "Governance address is not set"
    //     );
    //     require(profile.paused(), "ProfileNFT is not paused");
    //     require(box.paused(), "CyberBoxNFT is not paused");

    //     // TODO: add all checks
    // }

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
        Vm vm,
        ProfileNFT profile,
        CyberEngine engine,
        PermissionedFeeCreationMw mw
    ) internal {
        uint256 startingLink3 = LINK3_TREASURY.balance;
        uint256 startingEngine = ENGINE_TREASURY.balance;
        console.log(startingEngine);
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
        bytes32 digest;
        {
            bytes32 data = keccak256(
                abi.encode(
                    Constants._CREATE_PROFILE_TYPEHASH,
                    LINK3_SIGNER, // mint to this address
                    keccak256(bytes(handle)),
                    keccak256(
                        bytes(
                            "bafkreibcwcqcdf2pgwmco3pfzdpnfj3lijexzlzrbfv53sogz5uuydmvvu"
                        )
                    ),
                    keccak256(bytes("metadata")),
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
        profile.createProfile{ value: _INITIAL_FEE_TIER5 }(
            DataTypes.CreateProfileParams(
                LINK3_SIGNER,
                handle,
                "bafkreibcwcqcdf2pgwmco3pfzdpnfj3lijexzlzrbfv53sogz5uuydmvvu",
                "metadata"
            ),
            abi.encode(v, r, s, deadline)
        );
        require(mw.getNonce(address(profile), LINK3_SIGNER) == 1);
        require(profile.balanceOf(LINK3_SIGNER) == 1);
        require(
            LINK3_TREASURY.balance == startingLink3 + 0.00975 ether,
            "LINK3_TREASURY_BALANCE_INCORRECT"
        );
        console.log(ENGINE_TREASURY.balance);
        require(
            ENGINE_TREASURY.balance == startingEngine + 0.00025 ether,
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

    function deployLink3(
        address engine,
        Vm vm,
        bool writeFile
    ) internal returns (address profileProxy, address authority) {
        address essFac;
        address subFac;
        address profileFac;
        address profileImpl;

        {
            // TODO: reuse factory
            essFac = address(new EssenceNFTFactory());
            subFac = address(new SubscribeNFTFactory());
            profileFac = address(new ProfileNFTFactory());

            address authority;
            // address subImpl;
            // address essenceImpl;
            profileImpl = _computeAddress(
                type(ProfileNFT).creationCode,
                link3Salt,
                profileFac
            );

            authority = _computeAddress(
                abi.encodePacked(
                    type(RolesAuthority).creationCode,
                    abi.encode(LINK3_OWNER, address(0))
                ),
                link3Salt,
                engine
            );
            bytes memory data = abi.encodeWithSelector(
                ProfileNFT.initialize.selector,
                address(0),
                PROFILE_NAME,
                PROFILE_SYMBOL,
                authority
            );
            profileProxy = _computeAddress(
                abi.encodePacked(
                    type(ERC1967Proxy).creationCode,
                    abi.encode(profileImpl, data)
                ),
                link3Salt,
                engine
            );
        }
        if (writeFile) {
            _write(vm, "Profile Factory", profileFac);
            _write(vm, "Essence Factory", essFac);
            _write(vm, "Subscribe Factory", subFac);
        }
        address deployed;
        (deployed, authority) = CyberEngine(engine).createNamespace(
            DataTypes.CreateNamespaceParams(
                PROFILE_NAME,
                PROFILE_SYMBOL,
                LINK3_OWNER,
                DataTypes.ComputedAddresses(
                    profileProxy,
                    profileFac,
                    subFac,
                    essFac
                )
            )
        );
        require(deployed == profileProxy);
    }

    function deployLink3Descriptor(
        Vm vm,
        address _dc,
        bool writeFile,
        string memory animationUrl,
        address link3Profile,
        address authority
    ) internal {
        require(
            RolesAuthority(authority).owner() == LINK3_OWNER,
            "Authority owner is not LINK3_OWNER"
        );
        require(
            RolesAuthority(authority).owner() == msg.sender,
            "Authority owner is not msg.sender"
        );
        Create2Deployer dc = Create2Deployer(_dc);
        address impl = dc.deploy(
            abi.encodePacked(
                type(Link3ProfileDescriptor).creationCode,
                abi.encode(link3Profile)
            ),
            salt
        );
        if (writeFile) {
            _write(vm, "Link3 Descriptor (Impl)", impl);
        }

        address proxy = dc.deploy(
            abi.encodePacked(
                type(ERC1967Proxy).creationCode,
                abi.encode(
                    impl,
                    abi.encodeWithSelector(
                        Link3ProfileDescriptor.initialize.selector,
                        animationUrl
                    )
                )
            ),
            salt
        );
        if (writeFile) {
            _writeLastLine(vm, "Link3 Descriptor (Proxy)", proxy);
        }

        RolesAuthority(authority).setRoleCapability(
            Constants._PROFILE_GOV_ROLE,
            link3Profile,
            ProfileNFT.setNFTDescriptor.selector,
            true
        );
        RolesAuthority(authority).setUserRole(
            LINK3_OWNER,
            Constants._PROFILE_GOV_ROLE,
            true
        );

        // Need to have access to LINK3 OWNER
        ProfileNFT(link3Profile).setNFTDescriptor(proxy);
    }
}
