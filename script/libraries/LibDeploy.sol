// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;
import "forge-std/console.sol";
import { ProfileNFT } from "../../src/core/ProfileNFT.sol";
import { RolesAuthority } from "../../src/dependencies/solmate/RolesAuthority.sol";
import { CyberEngine } from "../../src/core/CyberEngine.sol";
import { CyberBoxNFT } from "../../src/periphery/CyberBoxNFT.sol";
import { CyberVault } from "../../src/periphery/CyberVault.sol";
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
import { EssenceDeployer } from "../../src/deployer/EssenceDeployer.sol";
import { SubscribeDeployer } from "../../src/deployer/SubscribeDeployer.sol";
import { ProfileDeployer } from "../../src/deployer/ProfileDeployer.sol";
import { LibString } from "../../src/libraries/LibString.sol";
import { DeploySetting } from "./DeploySetting.sol";

import "forge-std/Vm.sol";

library LibDeploy {
    struct ContractAddresses {
        address engineAuthority;
        address engineImpl;
        address link3DescriptorImpl;
        address link3DescriptorProxy;
        address engineProxyAddress;
        address cyberTreasury;
        address link3Profile;
        address link3ProfileMw;
        address calcEngineImpl;
        address calcEngineProxy;
        address essFac;
        address subFac;
        address profileFac;
        address subBeacon;
        address essBeacon;
    }
    struct DeployParams {
        bool isDeploy;
        bool writeFile; // write deployed contract addresses to file in deployment flow
        DeploySetting.DeployParameters setting; // passed in from deploy script or filled with test settings
    }

    // link3 specific setting
    string internal constant LINK3_NAME = "Link3";
    string internal constant LINK3_SYMBOL = "LINK3";
    bytes32 constant LINK3_SALT = keccak256(bytes(LINK3_NAME));

    // set engine owner to zero and let engine role authority handle access control
    address internal constant ENGINE_OWNER = address(0);

    // create2 deploy all contract with this protocol salt
    bytes32 constant SALT = keccak256(bytes("CyberConnect"));

    // Initial States
    uint256 internal constant _INITIAL_FEE_TIER0 = 10 ether;
    uint256 internal constant _INITIAL_FEE_TIER1 = 2 ether;
    uint256 internal constant _INITIAL_FEE_TIER2 = 1 ether;
    uint256 internal constant _INITIAL_FEE_TIER3 = 0.5 ether;
    uint256 internal constant _INITIAL_FEE_TIER4 = 0.1 ether;
    uint256 internal constant _INITIAL_FEE_TIER5 = 0.05 ether;
    uint256 internal constant _INITIAL_FEE_TIER6 = 0.01 ether;

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

    function _prepareToWrite(Vm vm) internal {
        vm.removeFile(_fileNameMd());
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
        address addr
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
    }

    function _write(
        Vm vm,
        string memory name,
        address addr
    ) internal {
        _writeHelper(vm, name, addr);
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

    // no longer used but kept for reference
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

    function deployInTest(
        Vm vm,
        address link3Signer,
        address link3Treasury,
        address engineTreasury
    ) internal returns (ContractAddresses memory addrs) {
        DeploySetting.DeployParameters memory setting = DeploySetting
            .DeployParameters(
                address(this),
                link3Signer,
                link3Treasury,
                address(this),
                address(this),
                engineTreasury,
                address(0) // deployer contract address. use 0 address to deploy create2 contract on the fly
            );
        DeployParams memory params = DeployParams(false, false, setting);
        addrs = deploy(
            vm,
            params,
            address(0x1890) // any EOA address to receive a link3 profile
        );
    }

    function deploy(
        Vm vm,
        DeployParams memory params,
        address mintToEOA
    ) internal returns (ContractAddresses memory addrs) {
        if (params.writeFile) {
            _prepareToWrite(vm);
            _writeText(vm, _fileNameMd(), "|Contract|Address|");
            _writeText(vm, _fileNameMd(), "|-|-|");
        }
        Create2Deployer dc;
        if (params.setting.deployerContract == address(0)) {
            console.log(
                "=====================deploying deployer contract================="
            );
            dc = new Create2Deployer(); // for running test
            if (params.writeFile) {
                console.log(
                    "==========================writing deployer contract=========================="
                );
                _write(vm, "Create2Deployer", address(dc));
            }
        } else {
            dc = Create2Deployer(params.setting.deployerContract); // for deployment
        }
        // 1. Deploy engine + link3 profile
        addrs = _deploy(vm, dc, params);
        // 2. Register a test profile
        if (block.chainid == 31337) {
            LibDeploy.registerLink3TestProfile(
                vm,
                RegisterLink3TestProfileParams(
                    ProfileNFT(addrs.link3Profile),
                    CyberEngine(addrs.engineProxyAddress),
                    PermissionedFeeCreationMw(addrs.link3ProfileMw),
                    mintToEOA,
                    params.setting.link3Treasury,
                    params.setting.engineTreasury
                )
            );
        }
        // 3. Health check
        healthCheck(
            addrs,
            params.setting.link3Signer,
            params.setting.link3Owner,
            params.setting.engineAuthOwner,
            params.setting.engineGov
        );
    }

    function deployBox(
        Vm vm,
        address dc,
        address link3Owner,
        bool writeFile
    ) internal returns (address boxImpl, address boxProxy) {
        boxImpl = Create2Deployer(dc).deploy(
            type(CyberBoxNFT).creationCode,
            SALT
        );
        if (writeFile) {
            _write(vm, "CyberBoxNFT (Impl)", boxImpl);
        }

        bytes memory _data = abi.encodeWithSelector(
            CyberBoxNFT.initialize.selector,
            link3Owner,
            "Link3 Mystery Box",
            "LINK3_MYSTERY_BOX"
        );
        boxProxy = Create2Deployer(dc).deploy(
            abi.encodePacked(
                type(ERC1967Proxy).creationCode,
                abi.encode(boxImpl, _data)
            ),
            SALT
        );
        if (writeFile) {
            _write(vm, "CyberBoxNFT (Proxy)", boxProxy);
        }
        require(CyberBoxNFT(boxProxy).paused(), "CYBERBOX_NOT_PAUSED");
    }

    function deployVault(
        Vm vm,
        address vaultOwner,
        bool writeFile
    ) internal returns (address vault) {
        vault = address(new CyberVault(vaultOwner));
        if (writeFile) {
            _write(vm, "CyberVault", vault);
        }
        require(CyberVault(vault).getSigner() == vaultOwner, "WRONG_SIGNER");
    }

    function _deploy(
        Vm vm,
        Create2Deployer dc,
        DeployParams memory params
    ) private returns (ContractAddresses memory addrs) {
        // check params
        if (!params.isDeploy) {
            require(params.setting.deployerContract == address(0));
            require(!params.writeFile);
        }

        // 0. Deploy RolesAuthority
        addrs.engineAuthority = dc.deploy(
            abi.encodePacked(
                type(RolesAuthority).creationCode,
                abi.encode(
                    params.setting.engineAuthOwner,
                    Authority(address(0))
                )
            ),
            SALT
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
            SALT,
            address(dc)
        );

        addrs.calcEngineProxy = _computeAddress(
            abi.encodePacked(
                type(ERC1967Proxy).creationCode,
                abi.encode(addrs.calcEngineImpl, data)
            ),
            SALT,
            address(dc)
        );

        // 1. Deploy Engine Impl
        addrs.engineImpl = dc.deploy(type(CyberEngine).creationCode, SALT);
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
            SALT
        );
        if (params.writeFile) {
            _write(vm, "EngineProxy", addrs.engineProxyAddress);
        }

        require(
            addrs.engineProxyAddress == addrs.calcEngineProxy,
            "ENGINE_PROXY_MISMATCH"
        );

        // 3. Set Governance Role
        RolesAuthority(addrs.engineAuthority).setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            addrs.engineProxyAddress,
            CyberEngine.allowProfileMw.selector,
            true
        );
        RolesAuthority(addrs.engineAuthority).setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            addrs.engineProxyAddress,
            CyberEngine.allowSubscribeMw.selector,
            true
        );
        RolesAuthority(addrs.engineAuthority).setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            addrs.engineProxyAddress,
            CyberEngine.allowEssenceMw.selector,
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
        RolesAuthority(addrs.engineAuthority).setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            addrs.engineProxyAddress,
            CyberEngine.upgradeSubscribeNFT.selector,
            true
        );
        RolesAuthority(addrs.engineAuthority).setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            addrs.engineProxyAddress,
            CyberEngine.upgradeEssenceNFT.selector,
            true
        );
        RolesAuthority(addrs.engineAuthority).setUserRole(
            params.setting.engineGov,
            Constants._ENGINE_GOV_ROLE,
            true
        );

        addrs.essFac = dc.deploy(type(EssenceDeployer).creationCode, SALT);
        addrs.subFac = dc.deploy(type(SubscribeDeployer).creationCode, SALT);
        addrs.profileFac = dc.deploy(type(ProfileDeployer).creationCode, SALT);
        if (params.writeFile) {
            _write(vm, "Profile Factory", addrs.profileFac);
            _write(vm, "Essence Factory", addrs.essFac);
            _write(vm, "Subscribe Factory", addrs.subFac);
        }
        // 4. Deploy Link3
        (
            addrs.link3Profile,
            addrs.subBeacon,
            addrs.essBeacon
        ) = createNamespace(
            addrs.engineProxyAddress,
            params.setting.link3Owner,
            LINK3_NAME,
            LINK3_SYMBOL,
            LINK3_SALT,
            addrs.profileFac,
            addrs.subFac,
            addrs.essFac
        );
        if (params.writeFile) {
            _write(vm, "Link3 Profile", addrs.link3Profile);
        }

        // 5. Deploy Protocol Treasury
        addrs.cyberTreasury = dc.deploy(
            abi.encodePacked(
                type(Treasury).creationCode,
                abi.encode(
                    params.setting.engineGov,
                    params.setting.engineTreasury,
                    250
                )
            ),
            SALT
        );
        if (params.writeFile) {
            _write(vm, "CyberConnect Treasury", addrs.cyberTreasury);
        }

        // 6. Deploy Profile Middleware
        addrs.link3ProfileMw = dc.deploy(
            abi.encodePacked(
                type(PermissionedFeeCreationMw).creationCode,
                abi.encode(addrs.engineProxyAddress, addrs.cyberTreasury)
            ),
            SALT
        );

        if (params.writeFile) {
            _write(
                vm,
                "Link3 Profile MW (PermissionedFeeCreationMw)",
                addrs.link3ProfileMw
            );
        }

        // 7. Engine Allow Middleware
        CyberEngine(addrs.engineProxyAddress).allowProfileMw(
            addrs.link3ProfileMw,
            true
        );

        // 8. Engine Config Link3 Profile Middleware
        CyberEngine(addrs.engineProxyAddress).setProfileMw(
            addrs.link3Profile,
            addrs.link3ProfileMw,
            abi.encode(
                params.setting.link3Signer,
                params.setting.link3Treasury,
                _INITIAL_FEE_TIER0,
                _INITIAL_FEE_TIER1,
                _INITIAL_FEE_TIER2,
                _INITIAL_FEE_TIER3,
                _INITIAL_FEE_TIER4,
                _INITIAL_FEE_TIER5,
                _INITIAL_FEE_TIER6
            )
        );
    }

    function healthCheck(
        ContractAddresses memory addrs,
        address link3Signer,
        address link3Owner,
        address engineAuthOwner,
        address engineGov
    ) internal view {
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
        require(
            ProfileNFT(addrs.link3Profile).getNamespaceOwner() == link3Owner,
            "ProfileNFT owner is not deployer"
        );
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
        require(
            RolesAuthority(addrs.engineAuthority).doesUserHaveRole(
                engineGov,
                Constants._ENGINE_GOV_ROLE
            ),
            "ENGINE_GOV_ROLE"
        );
        require(
            RolesAuthority(addrs.engineAuthority).owner() == engineAuthOwner,
            "ENGINE_AUTH_OWNER_WRONG"
        );
    }

    // avoid stack too deep
    string constant TEST_HANDLE = "cyberconnect";
    uint256 constant TEST_SIGNER_PK = 1;
    struct RegisterLink3TestProfileParams {
        ProfileNFT profile;
        CyberEngine engine;
        PermissionedFeeCreationMw mw;
        address mintToEOA;
        address link3Treasury;
        address engineTreasury;
    }

    // for testnet and test fixture
    function registerLink3TestProfile(
        Vm vm,
        RegisterLink3TestProfileParams memory params
    ) internal {
        address originSigner = params.mw.getSigner(address(params.profile));
        uint256 startingLink3 = params.link3Treasury.balance;
        uint256 startingEngine = params.engineTreasury.balance;
        address signer = vm.addr(TEST_SIGNER_PK);

        // change signer to tempory signer
        params.engine.setProfileMw(
            address(params.profile),
            address(params.mw),
            abi.encode(
                signer,
                params.link3Treasury,
                _INITIAL_FEE_TIER0,
                _INITIAL_FEE_TIER1,
                _INITIAL_FEE_TIER2,
                _INITIAL_FEE_TIER3,
                _INITIAL_FEE_TIER4,
                _INITIAL_FEE_TIER5,
                _INITIAL_FEE_TIER6
            )
        );
        require(
            params.mw.getSigner(address(params.profile)) == signer,
            "Signer is not set"
        );

        uint256 deadline = block.timestamp + 60 * 60 * 24 * 30; // 30 days
        address operator = address(0);
        bytes32 digest;
        {
            bytes32 data = keccak256(
                abi.encode(
                    Constants._CREATE_PROFILE_TYPEHASH,
                    params.mintToEOA,
                    keccak256(bytes(TEST_HANDLE)),
                    keccak256(
                        bytes(
                            "bafkreibcwcqcdf2pgwmco3pfzdpnfj3lijexzlzrbfv53sogz5uuydmvvu"
                        )
                    ),
                    keccak256(bytes("metadata")),
                    operator,
                    0,
                    deadline
                )
            );
            digest = TestLib712.hashTypedDataV4(
                address(params.mw),
                data,
                "PermissionedFeeCreationMw",
                "1"
            );
        }
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(TEST_SIGNER_PK, digest);

        require(
            params.mw.getNonce(address(params.profile), params.mintToEOA) == 0
        );
        params.profile.createProfile{ value: _INITIAL_FEE_TIER6 }(
            DataTypes.CreateProfileParams(
                params.mintToEOA,
                TEST_HANDLE,
                "bafkreibcwcqcdf2pgwmco3pfzdpnfj3lijexzlzrbfv53sogz5uuydmvvu",
                "metadata",
                address(0)
            ),
            abi.encode(v, r, s, deadline),
            new bytes(0)
        );
        require(
            params.mw.getNonce(address(params.profile), params.mintToEOA) == 1
        );
        require(params.profile.balanceOf(params.mintToEOA) == 1);
        require(
            params.link3Treasury.balance == startingLink3 + 0.00975 ether,
            "LINK3_TREASURY_BALANCE_INCORRECT"
        );
        require(
            params.engineTreasury.balance == startingEngine + 0.00025 ether,
            "ENGINE_TREASURY_BALANCE_INCORRECT"
        );

        // revert signer
        params.engine.setProfileMw(
            address(params.profile),
            address(params.mw),
            abi.encode(
                originSigner,
                params.link3Treasury,
                _INITIAL_FEE_TIER0,
                _INITIAL_FEE_TIER1,
                _INITIAL_FEE_TIER2,
                _INITIAL_FEE_TIER3,
                _INITIAL_FEE_TIER4,
                _INITIAL_FEE_TIER5,
                _INITIAL_FEE_TIER6
            )
        );
    }

    function computeProfileProxyAddr(
        address engine,
        address owner,
        string memory name,
        string memory symbol,
        bytes32 salt,
        address profileFac
    ) internal pure returns (address profileProxy) {
        address profileImpl;
        profileImpl = _computeAddress(
            type(ProfileNFT).creationCode,
            salt,
            profileFac
        );

        bytes memory data = abi.encodeWithSelector(
            ProfileNFT.initialize.selector,
            owner,
            name,
            symbol
        );
        profileProxy = _computeAddress(
            abi.encodePacked(
                type(ERC1967Proxy).creationCode,
                abi.encode(profileImpl, data)
            ),
            salt,
            engine
        );
    }

    function createNamespace(
        address engine,
        address owner,
        string memory name,
        string memory symbol,
        bytes32 salt,
        address profileFac,
        address subFac,
        address essFac
    )
        internal
        returns (
            address profileProxy,
            address subBeacon,
            address essBeacon
        )
    {
        address profileImpl;
        {
            profileImpl = _computeAddress(
                type(ProfileNFT).creationCode,
                salt,
                profileFac
            );

            bytes memory data = abi.encodeWithSelector(
                ProfileNFT.initialize.selector,
                owner,
                name,
                symbol
            );
            profileProxy = _computeAddress(
                abi.encodePacked(
                    type(ERC1967Proxy).creationCode,
                    abi.encode(profileImpl, data)
                ),
                salt,
                engine
            );
        }
        address deployed;
        (deployed, subBeacon, essBeacon) = CyberEngine(engine).createNamespace(
            DataTypes.CreateNamespaceParams(
                name,
                symbol,
                owner,
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

    // Can only run from owner of link3 profile contract
    function deployLink3Descriptor(
        Vm vm,
        address _dc,
        bool writeFile,
        string memory animationUrl,
        address link3Profile,
        address link3Owner
    ) internal {
        Create2Deployer dc = Create2Deployer(_dc);
        address impl = dc.deploy(
            abi.encodePacked(type(Link3ProfileDescriptor).creationCode),
            SALT
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
                        animationUrl,
                        link3Owner
                    )
                )
            ),
            SALT
        );
        if (writeFile) {
            _write(vm, "Link3 Descriptor (Proxy)", proxy);
        }

        // Need to have access to LINK3 OWNER
        ProfileNFT(link3Profile).setNFTDescriptor(proxy);

        require(
            ProfileNFT(link3Profile).getNFTDescriptor() == proxy,
            "NFT_DESCRIPTOR_NOT_SET"
        );
        // if (block.chainid == 31337) {
        //     string
        //         memory expected = "data:application/json;base64,eyJuYW1lIjoiQGN5YmVyY29ubmVjdCIsImRlc2NyaXB0aW9uIjoiTGluazMgcHJvZmlsZSBmb3IgQGN5YmVyY29ubmVjdCIsImltYWdlIjoiZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQSE4yWnlCM2FXUjBhRDBuTlRBd0p5Qm9aV2xuYUhROUp6VXdNQ2NnZG1sbGQwSnZlRDBuTUNBd0lEVXdNQ0ExTURBbklHWnBiR3c5SjI1dmJtVW5JSGh0Ykc1elBTZG9kSFJ3T2k4dmQzZDNMbmN6TG05eVp5OHlNREF3TDNOMlp5Y2dlRzFzYm5NNmVHeHBibXM5SjJoMGRIQTZMeTkzZDNjdWR6TXViM0puTHpFNU9Ua3ZlR3hwYm1zblBqeHpkSGxzWlQ1QVptOXVkQzFtWVdObElIdG1iMjUwTFdaaGJXbHNlVDBuSWs5MWRHWnBkQ0lzSUhOaGJuTXRjMlZ5YVdZN0ozMDhMM04wZVd4bFBqeHdZWFJvSUdROUowMDFPU0F4TURRdU9ESTJRelU1SURreUxqQTRNRFlnTmpJdU1EUTFNaUEzT1M0MU1UazNJRFkzTGpnNE1pQTJPQzR4T0RrMFREZzBMak15T1RrZ016WXVNall4TTBNNE9TNDBOelF4SURJMkxqSTNOVFFnT1RrdU56WTJJREl3SURFeE1DNDVPVGtnTWpCSU1UYzNMalUyT1VnME1qRXVNamMyUXpRek1pNHpNaklnTWpBZ05EUXhMakkzTmlBeU9DNDVOVFF6SURRME1TNHlOellnTkRCV05ESTRMalUyTmtNME5ERXVNamMySURRek55NDVPREVnTkRNMkxqZzFOaUEwTkRZdU9EVWdOREk1TGpNek9TQTBOVEl1TlRFNVREUXdOaTR5TmpJZ05EWTVMamt5TVVNek9UY3VOVGc0SURRM05pNDBOaklnTXpnM0xqQXlJRFE0TUNBek56WXVNVFUzSURRNE1FZ3hPREl1TnpJMFNEYzVRelkzTGprMU5ETWdORGd3SURVNUlEUTNNUzR3TkRZZ05Ua2dORFl3VmpFd05DNDRNalphSnlCbWFXeHNQU2RpYkdGamF5Y3ZQangwWlhoMElIUmxlSFF0WVc1amFHOXlQU2RsYm1RbklHUnZiV2x1WVc1MExXSmhjMlZzYVc1bFBTZG9ZVzVuYVc1bkp5QjRQU2MwTVRJbklIazlKelV3SnlCbWFXeHNQU2NqWm1abUp5Qm1iMjUwTFhkbGFXZG9kRDBuTnpBd0p5Qm1iMjUwTFdaaGJXbHNlVDBuSWs5MWRHWnBkQ0lzSUhOaGJuTXRjMlZ5YVdZbklHWnZiblF0YzJsNlpUMG5NekluUG1ONVltVnlZMjl1Ym1WamREd3ZkR1Y0ZEQ0OGFXMWhaMlVnZUQwbk1qQXVOamtsSnlCNVBTYzBNaTQzTWlVbklHaHlaV1k5SjJSaGRHRTZhVzFoWjJVdmMzWm5LM2h0YkR0aVlYTmxOalFzVUVoT01scDVRakphV0VwNllWYzVkVkJUU1hoTWFrVnBTVWhvZEdKSE5YcFFVMHB2WkVoU2QwOXBPSFprTTJRelRHNWpla3h0T1hsYWVUaDVUVVJCZDB3elRqSmFlVWxuWkRKc2EyUkhaemxKYWtWM1RVTlZhVWxIYUd4aFYyUnZaRVF3YVUxVVFYZEtVMGxuWkcxc2JHUXdTblpsUkRCcFRVTkJkMHhxVldkTmFtdG5UV3ByYVZCcWVIZFpXRkp2U1VkUk9VbHJNSGRNUkVaelRubDNkMGxGTUhoTmVYZDRZa1JGYzAxRFFrNU5WRlZ6VFZkM2VVeEVRV2RVVkVVMFRFUkdjMDE1ZDNkSlJUQjVUV2wzZUdKRVkzTk5RMEpPVFVOM2VXSkVSWE5OUTBKT1RtbDNlV0pFUlhOTlEwSk9UME4zZVdKRVJYTk5RMEpPVFZSQmMwMXRkekZNUkVGblZGUkZNMHhFU25OTmFYZDNTVVV3ZVUxcGQzbGlSRVZ6VFVOQ1RrMXFaM05OYlhkNFRFUkJaMVJVUVhOTk1uZDRURVJCWjFSVVNYTk5NbmQ2VEVSQloxUlVXWE5OTW5kNFRFUkJaMVJVUlhoTVJFNXpUVk4zZDBsRk1IaE5lWGQ2WWtSRmMwMURRazVOVkZselRUSjNlRXhFUVdkVVZFVTFURVJPYzAxVGQzZEpSVEI1VFdsM2VtSkVSWE5OUTBKT1RXcFJjMDB5ZDNwTVJFRm5WRlJKTkV4RVRuTk5VM2QzU1VVd2QweEVVbk5OVTNkM1NVVXdlVXhFVW5OTmVYZDNTVVV3TWt4RVVuTk5VM2QzU1VVd05FeEVVbk5PVTNkM1NVVXdlRTVEZHpCaVJFVnpUVU5DVGsxVVkzTk9SM2Q0VEVSQloxUlVTWGRNUkZKelRWTjNkMGxGTUhsTmFYY3dZa1JGYzAxRFFrNU5hbEZ6VGtkM2VreEVRV2RVVkVrMFRFUlNjMDFUZDNkSlJUQjNURVJXYzAxVGQzZEpSVEI1VEVSV2MwMTVkM2RKUlRBeVRFUldjMDFUZDNkSlJUQjRUWGwzTVdKRVJYTk5RMEpPVFZSVmMwNVhkekpNUkVGblZGUkplVXhFVm5OTlUzZDNTVVV3ZVU1RGR6RmlSRTF6VFVOQ1RrMXFaM05PVjNkNFRFUkJaMVJVUVhOT2JYZDRURVJCWjFSVVdYTk9iWGQ0VEVSQloxUlVaM05PYlhkNFRFUkJaMVJVUlhkTVJGcHpUbE4zZDBsRk1IaE9lWGN5WWtSRmMwMURRazVOYWtGelRtMTNlRXhFUVdkVVZFbDVURVJhYzAxVGQzZEpSVEI1VDBOM01tSkVSWE5OUTBKT1RVTjNNMkpFWTNOTlEwSk9UME4zTTJKRVJYTk5RMEpPVFZSQmMwNHlkM2hNUkVGblZGUkZlVXhFWkhOTlUzZDNTVVV3ZUU1RGR6TmlSRVZ6VFVOQ1RrMVVXWE5PTW5kNFRFUkJaMVJVUlRSTVJHUnpUVk4zZDBsRk1IbE5RM2N6WWtSRmMwMURRazVOYWtselRqSjNNMHhFUVdkVVZFVjRURVJvYzAxVGQzZEpSVEI0VFhsM05HSkVSWE5OUTBKT1RWUlpjMDlIZDNoTVJFRm5WRlJKZDB4RWFITk5VM2QzU1VVd2QweEViSE5PVTNkM1NVVXdNa3hFYkhOT2VYZDNTVVV3ZUU1RGR6VmlSRVZ6VFVOQ1RrMVVZM05QVjNkNFRFUkJaMVJVU1hoTVJHeHpUVk4zZDBsRk1IbE5lWGMxWWtSRmMwMURRazVOYWxWelQxZDNlRXhFUVdkVVZFa3pURVJzYzAxVGQzZEpSVEI0VEVSRmQySkVTWE5OUTBKT1RsTjNlRTFIZDNoTVJFRm5WRlJqYzAxVVFuTk5VM2QzU1VVd05VeEVSWGRpUkVWelRVTkNUazFVVFhOTlZFSnpUVk4zZDBsRk1IaE9VM2Q0VFVkM01reEVRV2RVVkVsNVRFUkZkMkpFUlhOTlEwSk9UV3BSYzAxVVFuTk5VM2QzU1VVd2VVOURkM2hOUjNkNFRFUkJaMVJVUVhOTlZFWnpUVk4zZDBsRk1IbE1SRVY0WWtSRmMwMURRazVPUTNkNFRWZDNNa3hFUVdkVVZFVjRURVJGZUdKRVVYTk5RMEpPVFZSamMwMVVSbk5OVTNkM1NVVXdlVTFUZDNoTlYzZDRURVJCWjFSVVNYcE1SRVY0WWtSRmMwMURRazVOYVhkNFRXMTNla3hFUVdkVVZHTnpUVlJLYzAxVGQzZEpSVEExVEVSRmVXSkVUWE5OUTBKT1RWUk5jMDFVU25OTlUzZDNTVVV3ZUU1cGQzaE5iWGQ0VEVSQloxUlVSVFJNUkVWNVlrUkpjMDFEUWs1TmFrbHpUVlJLYzAxVGQzZEpSVEI1VGxOM2VFMXRkM2hNUkVGblZGUkpNMHhFUlhsaVJFVnpUVU5DVGsxRGQzaE5NbmQ0VEVSQloxUlVTWE5OVkU1elRXbDNkMGxGTURKTVJFVjZZa1JSYzAxRFFrNU5WRVZ6VFZST2MwMXBkM2RKUlRCNFRrTjNlRTB5ZDNoTVJFRm5WRlJGTTB4RVJYcGlSRVZ6VFVOQ1RrMXFSWE5OVkU1elRWTjNkMGxGTUhsT1UzZDRUVEozZVV4RVFXZFVWRUZ6VFZSU2MwMTVkM2RKUlRBeFRFUkZNR0pFUlhOTlEwSk9UME4zZUU1SGQzaE1SRUZuVkZSRmQweEVSVEJpUkVWelRVTkNUazFVVFhOTlZGSnpUVk4zZDBsRk1IaE9VM2Q0VGtkM2VFMURkM2RKUlRCNVQwTjNlRTVIZDNoTVJFRm5WRlJCYzAxVVZuTk5VM2QzU1VVd01reEVSVEZpUkVselRVTkNUazlUZDNoT1YzZDRURVJCWjFSVVJYaE1SRVV4WWtSUmMwMURRazVOVkdOelRWUldjMDFUZDNkSlJUQjVUVU4zZUU1WGQzaE1SRUZuVkZSSmVVeEVSVEZpUkVWelRVTkNUazFxVlhOTlZGWnpUV2wzZDBsRk1IZE1SRVV5WWtSRmMwMURRazVOYVhkNFRtMTNlRXhFUVdkVVZGRnpUVlJhYzAxVGQzZEpSVEExVEVSRk1tSkVUWE5OUTBKT1RWUk5jMDFVV25OTlUzZDNTVVV3ZUU1cGQzaE9iWGQ0VEVSQloxUlVSVFJNUkVVeVlrUkZjMDFEUWs1TmFrVnpUVlJhYzAxNWQzZEpSVEI1VG5sM2VFNXRkM2hNUkVGblZGUkZjMDFVWkhOTmFYZDNTVVV3TVV4RVJUTmlSRWx6VFVOQ1RrMVVSWE5OVkdSelRXbDNkMGxGTUhoT1EzZDRUakozZUV4RVFXZFVWRVV6VEVSRk0ySkVSWE5OUTBKT1RWUnJjMDFVWkhOTmFYZDNTVVV3ZVU1VGQzaE9NbmQ1VEVSQloxUlVTWE5OVkdoelRXbDNkMGxGTURSTVJFVTBZa1JOYzAxRFFrNU5WRTF6VFZSb2MwMVRkM2RKUlRCNFRsTjNlRTlIZDNsTVJFRm5WRlJGTkV4RVJUUmlSRTF6VFVOQ1RrMXFTWE5OVkdoelRYbDNkMGxGTUhsT2FYZDRUMGQzZUV4RVFXZFVWRWswVEVSRk5HSkVSWE5OUTBKT1RYbDNlRTlYZDNoTVJFRm5WRlJaYzAxVWJITk5lWGQzU1VVd2VFMVRkM2hQVjNjd1RFUkJaMVJVU1hkTVJFVTFZa1JGYzAxRFFrNU5hazF6VFZSc2MwMXBkM2RKUlRCNVRtbDNlRTlYZDNoTVJFRm5WRlJOYzAxcVFuTk5hWGQzU1VVd00weEVTWGRpUkZWelRVTkNUazFVVFhOTmFrSnpUVk4zZDBsRk1IaE9hWGQ1VFVkM2VFeEVRV2RVVkVVMVRFUkpkMkpFUlhOTlEwSk9UV3BGYzAxcVFuTk5VM2QzU1VVd2VVNTVkM2xOUjNkNFRFUkJaMVJVU1hOTmFrWnpUVk4zZDBsRk1EQk1SRWw0WWtSRmMwMURRazVPYVhkNVRWZDNla3hFUVdkVVZFVjNURVJKZUdKRVRYTk5RMEpPVFZSUmMwMXFSbk5OVTNkM1NVVXdlRTU1ZDNsTlYzZDRURVJCWjFSVVNYZE1SRWw0WWtSVmMwMURRazVOYWxselRXcEdjMDE1ZDNkSlJUQTBURVJKZVdKRVJYTk5RMEpPVFZSQmMwMXFTbk5OVTNkM1NVVXdlRTE1ZDNsTmJYZDRURVJCWjFSVVJURk1SRWw1WWtSSmMwMURRazVOVkdkelRXcEtjMDFUZDNkSlJUQjVUVU4zZVUxdGQzaE1SRUZuVkZSSk1FeEVTWGxpUkZWelRVTkNUazFEZDNsTk1uY3pURVJCWjFSVVozTk5hazV6VG5sM2QwbEZNSGhPZVhkNVRUSjNNRXhFUVdkVVZFbDVURVJKZW1KRVJYTk5RMEpPVFdwUmMwMXFUbk5OZVhkM1NVVXdkMHhFU1RCaVJFVnpUVU5DVGs1cGQzbE9SM2Q0VEVSQloxUlVhM05OYWxKelRWTjNkMGxGTUhoTlUzZDVUa2QzZUV4RVFXZFVWRVY2VEVSSk1HSkVSWE5OUTBKT1RWUlpjMDFxVW5OTlUzZDNTVVV3ZUU5VGQzbE9SM2Q1VEVSQloxUlVTVEJNUkVrd1lrUkZjMDFEUWs1TlEzZDVUbGQzZUV4RVFXZFVWRWx6VFdwV2MwMTVkM2RKUlRBeVRFUkpNV0pFUlhOTlEwSk9UME4zZVU1WGR6Rk1SRUZuVkZSRk1FeEVTVEZpUkVWelRVTkNUazFVWTNOTmFsWnpUVk4zZDBsRk1IbE5RM2Q1VGxkM01VeEVRV2RVVkVreVRFUkpNV0pFUlhOTlEwSk9UV3BuYzAxcVZuTk5VM2QzU1VVd2QweEVTVEppUkVWelRVTkNUazFwZDNsT2JYZDZURVJCWjFSVVdYTk5hbHB6VFZOM2QwbEZNRFJNUkVreVlrUkZjMDFEUWs1TlZFMXpUV3BhYzAxVGQzZEpSVEI0VGxOM2VVNXRkM2xNUkVGblZGUkZOVXhFU1RKaVJFbHpUVU5DVGsxcVZYTk5hbHB6VFdsM2QwbEZNSGRNUkVrellrUkZjMDFEUWs1TmFYZDVUakozZWt4RVFXZFVWRmx6VFdwa2MwMVRkM2RKUlRBMFRFUkpNMkpFUlhOTlEwSk9UVlJCYzAxcVpITk9VM2QzU1VVd2VFOVRkM2xPTW5jMVRFUkJaMVJVUVhOTmFtaHpUVk4zZDBsRk1ESk1SRWswWWtSRmMwMURRazVQUTNkNVQwZDNlRXhFUVdkVVZFVjNURVJKTkdKRVNYTk5RMEpPVFZSTmMwMXFhSE5OVTNkM1NVVXdlRTVwZDNsUFIzZDRURVJCWjFSVVJUUk1SRWswWWtSRmMwMURRazVOYWtGelRXcG9jMDFUZDNkSlJUQjVUV2wzZVU5SGQzaE1SRUZuVkZSSk1FeEVTVFJpUkVselRVTkNUazFxWTNOTmFtaHpUVk4zZDBsRk1IZE1SRWsxWWtSamMwMURRazVQUTNkNVQxZDNlRXhFUVdkVVZFVjRURVJKTldKRVNYTk5RMEpPVFZSUmMwMXFiSE5OVTNkM1NVVXdlRTlEZDNsUFYzZDRURVJCWjFSVVNYbE1SRWsxWWtSSmMwMURRazVOYWxselRXcHNjMDFUZDNkSlEwbG5Zek5TZVdJeWRHeFFVMG96WVVkc01GcFRTV2RqTTFKNVlqSjBiRXhZWkhCYVNGSnZVRk5KZUVscFFtMWhWM2h6VUZOS2RXSXlOV3hKYVRnclVFTTVlbVJ0WXlzbklIZHBaSFJvUFNjek1pNHpNRFVsSnlCb1pXbG5hSFE5SnpNeUxqTXdOU1VuSUc5d1lXTnBkSGs5SnpBdU15Y3ZQanhuSUhOMGVXeGxQU2QwY21GdWMyWnZjbTA2ZEhKaGJuTnNZWFJsS0RFNUxqWXlOaVVzSURnekxqZ2xLU2MrUEhSbGVIUWdaRzl0YVc1aGJuUXRZbUZ6Wld4cGJtVTlKMmhoYm1kcGJtY25JSGc5SnpBbklIazlKekFuSUdacGJHdzlKeU5tWm1ZbklHWnZiblF0YzJsNlpUMG5Nakp3ZUNjZ1ptOXVkQzEzWldsbmFIUTlKemN3TUNjZ1ptOXVkQzFtWVcxcGJIazlKeUpQZFhSbWFYUWlMQ0J6WVc1ekxYTmxjbWxtSno1c2FXNXJNeTUwYnk4OEwzUmxlSFErUEhKbFkzUWdkMmxrZEdnOUp6RTNNM0I0SnlCb1pXbG5hSFE5SnpJMGNIZ25JSEo0UFNjMGNIZ25JSEo1UFNjMGNIZ25JR1pwYkd3OUp5Tm1abVluSUhSeVlXNXpabTl5YlQwbmMydGxkMWdvTFRJMUtTY2dlRDBuT1RVbklIazlKeTB6Snk4K1BIUmxlSFFnWkc5dGFXNWhiblF0WW1GelpXeHBibVU5SjJoaGJtZHBibWNuSUhSbGVIUXRZVzVqYUc5eVBTZHpkR0Z5ZENjZ2VEMG5NVEF3SnlCNVBTY3RNU2NnWm05dWRDMTNaV2xuYUhROUp6UXdNQ2NnWm05dWRDMW1ZVzFwYkhrOUp5SlBkWFJtYVhRaUxDQnpZVzV6TFhObGNtbG1KeUJtYjI1MExYTnBlbVU5SnpJeWNIZ25JR1pwYkd3OUp5TXdNREFuUG1ONVltVnlZMjl1Ym1WamREd3ZkR1Y0ZEQ0OEwyYytQQzl6ZG1jKyIsImFuaW1hdGlvbl91cmwiOiJodHRwczovL2N5YmVyY29ubmVjdC5teXBpbmF0YS5jbG91ZC9pcGZzL2JhZmtyZWlidTY0ZzRteDRpa3RvczJpbG42cHl5NTYzdHRteHZlZDJ3MmFsdzdqbDRkb2ZnY3M3b2dlP2hhbmRsZT1jeWJlcmNvbm5lY3QiLCJhdHRyaWJ1dGVzIjpbeyJ0cmFpdF90eXBlIjoiaWQiLCJ2YWx1ZSI6IjEifSx7InRyYWl0X3R5cGUiOiJsZW5ndGgiLCJ2YWx1ZSI6IjEyIn0seyJ0cmFpdF90eXBlIjoic3Vic2NyaWJlcnMiLCJ2YWx1ZSI6IjAifSx7InRyYWl0X3R5cGUiOiJoYW5kbGUiLCJ2YWx1ZSI6IkBjeWJlcmNvbm5lY3QifV19";
        //     require(
        //         keccak256(bytes(ProfileNFT(link3Profile).tokenURI(1))) ==
        //             keccak256(bytes(expected)),
        //         "PROFILE_NFT_URI_WRONG"
        //     );
        // }
    }
}
