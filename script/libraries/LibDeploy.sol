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
    struct ContractAddresses {
        address engineAuthority;
        address engineImpl;
        address link3DescriptorImpl;
        address link3DescriptorProxy;
        // address profileImpl; // not used
        // address subscribeImpl; // not used
        // address subscribeBeacon; // not used
        // address essenceBeacon; // not used
        address engineProxyAddress;
        address boxImpl;
        address boxProxy;
        address cyberTreasury;
        address link3Profile;
        address link3ProfileMw;
        address calcEngineImpl;
        address calcEngineProxy;
        // address link3Authority;
    }
    struct DeployParams {
        // address deployer; // 1. in test it is the Test contract. 2. in deployment it is msg.sender (deployer)
        bool isDeploy;
        address deployerContract; // Create2Deployer. in test this is expected to be address(0)
        bool writeFile; // write deployed contract addresses to file in deployment flow
        address link3Owner; // 1. in test, use Test contract so that signing process still works. 2. in deployment use real owner.
        address link3Signer; // 1. in test, use Test contract so that signing process still works. 2. in deployment use real owner.
        address engineAuthOwner; // 1. in test use Test contract 2. in deployment use msg.sender (deployer)
        address engineGov; // 1. in test use Test contract 2. in deployment use real address
        address link3TestProfileMintToEOA;
    }

    string internal constant LINK3_NAME = "Link3";
    string internal constant LINK3_SYMBOL = "LINK3";
    // TODO: Fix engine owner, use 0 address for integration test.
    // have to be different from deployer to make tests useful
    address internal constant ENGINE_OWNER = address(0);

    // TODO: change for prod
    address internal constant ENGINE_TREASURY =
        0x1890a1625d837A809b0e77EdE1a999a161df085d;
    bytes32 constant salt = keccak256(bytes("CyberConnect"));
    bytes32 constant link3Salt = keccak256(bytes(LINK3_NAME));
    address internal constant LINK3_TREASURY =
        0xaB24749c622AF8FC567CA2b4d3EC53019F83dB8F;

    // currently the engine gov is always deployer
    // TODO: change for prod

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
    function deployInTest(Vm vm)
        internal
        returns (ContractAddresses memory addrs)
    {
        return
            deploy(
                vm,
                DeployParams(
                    false,
                    address(0),
                    false,
                    address(this),
                    address(this),
                    address(this),
                    address(this),
                    address(0x1890)
                )
            );
    }

    function deploy(Vm vm, DeployParams memory params)
        internal
        returns (ContractAddresses memory addrs)
    {
        // 1. Deploy engine + link3 profile
        addrs = _deploy(vm, params);
        // 2. Register a test profile
        if (block.chainid != 1) {
            LibDeploy.registerLink3TestProfile(
                vm,
                ProfileNFT(addrs.link3Profile),
                CyberEngine(addrs.engineProxyAddress),
                PermissionedFeeCreationMw(addrs.link3ProfileMw),
                params.link3TestProfileMintToEOA
            );
        }
        // 3. Health check
    }

    function _deploy(Vm vm, DeployParams memory params)
        private
        returns (ContractAddresses memory addrs)
    {
        // check params
        if (!params.isDeploy) {
            require(params.deployerContract == address(0));
            require(!params.writeFile);
        }
        if (params.writeFile) {
            _prepareToWrite(vm);
            _writeText(vm, _fileNameJson(), "{");
            _writeText(vm, _fileNameMd(), "|Contract|Address|");
            _writeText(vm, _fileNameMd(), "|-|-|");
        }

        Create2Deployer dc;
        if (params.deployerContract == address(0)) {
            console.log(
                "=====================deploying deployer contract================="
            );
            dc = new Create2Deployer(); // for running test
            if (params.writeFile) {
                _write(vm, "Create2Deployer", address(dc));
            }
        } else {
            dc = Create2Deployer(params.deployerContract); // for deployment
        }

        // 0. Deploy RolesAuthority
        addrs.engineAuthority = dc.deploy(
            abi.encodePacked(
                type(RolesAuthority).creationCode,
                abi.encode(params.engineAuthOwner, Authority(address(0))) // use deployer here so that 1. in test, deployer is Test contract 2. in deployment, deployer is the msg.sender
            ),
            salt
        );
        if (params.writeFile) {
            _write(vm, "RolesAuthority", addrs.engineAuthority);
        }

        bytes memory data = abi.encodeWithSelector(
            CyberEngine.initialize.selector,
            ENGINE_OWNER,
            address(addrs.engineAuthority)
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
        if (params.writeFile) {
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
        if (params.writeFile) {
            _write(vm, "EngineProxy", addrs.engineProxyAddress);
        }

        require(
            addrs.engineProxyAddress == addrs.calcEngineProxy,
            "ENGINE_PROXY_MISMATCH"
        );

        // 5. Set Governance Role
        RolesAuthority(addrs.engineAuthority).setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            addrs.engineProxyAddress,
            CyberEngine.allowProfileMw.selector,
            true
        );
        RolesAuthority(addrs.engineAuthority).setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            addrs.engineProxyAddress,
            CyberEngine.createNamespace.selector,
            true
        );
        RolesAuthority(addrs.engineAuthority).setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            addrs.engineProxyAddress,
            CyberEngine.setProfileMw.selector,
            true
        );
        RolesAuthority(addrs.engineAuthority).setUserRole(
            params.engineGov, //use deployer here so that 1. in test, deployer is Test contract 2. in deployment, deployer is the msg.sender
            Constants._ENGINE_GOV_ROLE,
            true
        );

        // 6. Deploy Link3
        addrs.link3Profile = deployLink3(
            addrs.engineProxyAddress,
            vm,
            params.writeFile,
            params.link3Owner
        );
        if (params.writeFile) {
            _write(vm, "Link3 Profile", addrs.link3Profile);
        }

        // 7. Deploy Protocol Treasury
        addrs.cyberTreasury = dc.deploy(
            abi.encodePacked(
                type(Treasury).creationCode,
                abi.encode(params.engineGov, ENGINE_TREASURY, 250)
            ),
            salt
        );
        if (params.writeFile) {
            _write(vm, "CyberConnect Treasury", addrs.cyberTreasury);
        }

        // 8. Deploy Profile Middleware
        addrs.link3ProfileMw = dc.deploy(
            abi.encodePacked(
                type(PermissionedFeeCreationMw).creationCode,
                abi.encode(addrs.engineProxyAddress, addrs.cyberTreasury)
            ),
            salt
        );

        if (params.writeFile) {
            _write(
                vm,
                "Link3 Profile MW (PermissionedFeeCreationMw)",
                addrs.link3ProfileMw
            );
        }

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
                params.link3Signer,
                LINK3_TREASURY,
                _INITIAL_FEE_TIER0,
                _INITIAL_FEE_TIER1,
                _INITIAL_FEE_TIER2,
                _INITIAL_FEE_TIER3,
                _INITIAL_FEE_TIER4,
                _INITIAL_FEE_TIER5
            )
        );

        // scope to avoid stack too deep error
        // 11. Deploy BoxNFT Impl
        addrs.boxImpl = dc.deploy(type(CyberBoxNFT).creationCode, salt);
        if (params.writeFile) {
            _write(vm, "CyberBoxNFT (Impl)", addrs.boxImpl);
        }

        // 12. Deploy Proxy for BoxNFT
        bytes memory _data = abi.encodeWithSelector(
            CyberBoxNFT.initialize.selector,
            params.link3Owner,
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
        if (params.writeFile) {
            _write(vm, "CyberBoxNFT (Proxy)", addrs.boxProxy);
        }

        // TODO: fix this
        if (params.writeFile) {
            _writeText(vm, _fileNameJson(), "}");
        }
    }

    function healthCheck(ContractAddresses memory addrs, address link3Signer)
        internal
        view
    {
        string memory name = CyberEngine(addrs.engineProxyAddress)
            .getNameByNamespace(addrs.link3Profile);
        address mw = CyberEngine(addrs.engineProxyAddress)
            .getProfileMwByNamespace(addrs.link3Profile);
        require(mw == addrs.link3ProfileMw, "WRONG_PROFILE_MW");
        require(
            keccak256(abi.encodePacked(name)) ==
                keccak256(abi.encodePacked(LINK3_NAME)),
            "WRONG_NAME"
        );
        // TODO: fix this after ownable
        // require(
        //     profile.owner() == ENGINE_OWNER,
        //     "ProfileNFT owner is not deployer"
        // );
        // require(
        //     authority.canCall(
        //         deployer,
        //         address(profile),
        //         ProfileNFT.setSigner.selector
        //     ),
        //     "ProfileNFT Owner can set Signer"
        // );
        // require(
        //     authority.doesUserHaveRole(deployer, Constants._PROFILE_GOV_ROLE),
        //     "Governance address is not set"
        // );
        require(
            PermissionedFeeCreationMw(addrs.link3ProfileMw).getSigner(
                addrs.link3Profile
            ) == link3Signer,
            "LINK3_SIGNER_WRONG"
        );
        require(
            keccak256(
                abi.encodePacked(ProfileNFT(addrs.link3Profile).name())
            ) == keccak256(abi.encodePacked(LINK3_NAME)),
            "LINK3_WRONG_NAME"
        );
        require(
            keccak256(
                abi.encodePacked(ProfileNFT(addrs.link3Profile).symbol())
            ) == keccak256(abi.encodePacked(LINK3_SYMBOL)),
            "LINK3_WRONG_SYMBOL"
        );
        require(ProfileNFT(addrs.link3Profile).paused(), "LINK3_NOT_PAUSED");
        require(CyberBoxNFT(addrs.boxProxy).paused(), "CYBERBOX_NOT_PAUSED");
    }

    string constant TEST_HANDLE = "cyberconnect";
    // set signer
    uint256 constant TEST_SIGNER_PK = 1;

    // for testnet, profile owner is all deployer, signer is fake
    function registerLink3TestProfile(
        Vm vm,
        ProfileNFT profile,
        CyberEngine engine,
        PermissionedFeeCreationMw mw,
        address mintToEOA
    ) internal {
        address originSigner = mw.getSigner(address(profile));
        uint256 startingLink3 = LINK3_TREASURY.balance;
        uint256 startingEngine = ENGINE_TREASURY.balance;
        console.log(startingEngine);
        address signer = vm.addr(TEST_SIGNER_PK);

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
                    mintToEOA, // mint to this address
                    keccak256(bytes(TEST_HANDLE)),
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
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(TEST_SIGNER_PK, digest);

        require(mw.getNonce(address(profile), mintToEOA) == 0);
        profile.createProfile{ value: _INITIAL_FEE_TIER5 }(
            DataTypes.CreateProfileParams(
                mintToEOA, // use LINK3_SIGNER instead of deployer since deployer could be a contract in anvil environment and safeMint will fail
                TEST_HANDLE,
                "bafkreibcwcqcdf2pgwmco3pfzdpnfj3lijexzlzrbfv53sogz5uuydmvvu",
                "metadata"
            ),
            abi.encode(v, r, s, deadline),
            new bytes(0)
        );
        require(mw.getNonce(address(profile), mintToEOA) == 1);
        require(profile.balanceOf(mintToEOA) == 1);
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
                originSigner,
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
        bool writeFile,
        address link3Owner
    ) internal returns (address profileProxy) {
        address essFac;
        address subFac;
        address profileFac;
        address profileImpl;
        {
            // TODO: reuse factory
            essFac = address(new EssenceNFTFactory());
            subFac = address(new SubscribeNFTFactory());
            profileFac = address(new ProfileNFTFactory());

            profileImpl = _computeAddress(
                type(ProfileNFT).creationCode,
                link3Salt,
                profileFac
            );

            bytes memory data = abi.encodeWithSelector(
                ProfileNFT.initialize.selector,
                link3Owner,
                LINK3_NAME,
                LINK3_SYMBOL
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
        address deployed = CyberEngine(engine).createNamespace(
            DataTypes.CreateNamespaceParams(
                LINK3_NAME,
                LINK3_SYMBOL,
                link3Owner,
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
        address authority,
        address link3Owner
    ) internal {
        require(
            RolesAuthority(authority).owner() == link3Owner,
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
            link3Owner,
            Constants._PROFILE_GOV_ROLE,
            true
        );

        // Need to have access to LINK3 OWNER
        ProfileNFT(link3Profile).setNFTDescriptor(proxy);
        // TODO: check tokenURI
    }
}
