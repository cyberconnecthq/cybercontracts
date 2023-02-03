// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;
import "forge-std/console.sol";
import { Actions } from "../../src/libraries/Actions.sol";
import { ProfileNFT } from "../../src/core/ProfileNFT.sol";
import { RolesAuthority } from "../../src/dependencies/solmate/RolesAuthority.sol";
import { CyberEngine } from "../../src/core/CyberEngine.sol";
import { CyberBoxNFT } from "../../src/periphery/CyberBoxNFT.sol";
import { CyberGrandNFT } from "../../src/periphery/CyberGrandNFT.sol";
import { FrameNFT } from "../../src/periphery/FrameNFT.sol";
import { MBNFT } from "../../src/periphery/MBNFT.sol";
import { CyberVault } from "../../src/periphery/CyberVault.sol";
import { RelationshipChecker } from "../../src/periphery/RelationshipChecker.sol";
import { CYBER } from "../../src/token/CYBER.sol";
import { SubscribeNFT } from "../../src/core/SubscribeNFT.sol";
import { EssenceNFT } from "../../src/core/EssenceNFT.sol";
import { Authority } from "../../src/dependencies/solmate/Auth.sol";
import { UpgradeableBeacon } from "../../src/upgradeability/UpgradeableBeacon.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { TimelockController } from "openzeppelin-contracts/contracts/governance/TimelockController.sol";
import { Constants } from "../../src/libraries/Constants.sol";
import { DataTypes } from "../../src/libraries/DataTypes.sol";
import { Link3ProfileDescriptor } from "../../src/periphery/Link3ProfileDescriptor.sol";
import { Link3ProfileDescriptorV2 } from "../../src/periphery/Link3ProfileDescriptorV2.sol";
import { TestLib712 } from "../../test/utils/TestLib712.sol";
import { Treasury } from "../../src/middlewares/base/Treasury.sol";
import { PermissionedFeeCreationMw } from "../../src/middlewares/profile/PermissionedFeeCreationMw.sol";
import { StableFeeCreationMw } from "../../src/middlewares/profile/StableFeeCreationMw.sol";
import { CollectPermissionMw } from "../../src/middlewares/essence/CollectPermissionMw.sol";
import { SubscribePaidMw } from "../../src/middlewares/subscribe/SubscribePaidMw.sol";
import { SubscribeOnlyOnceMw } from "../../src/middlewares/subscribe/SubscribeOnlyOnceMw.sol";
import { SubscribeDisallowedMw } from "../../src/middlewares/subscribe/SubscribeDisallowedMw.sol";
import { CollectPaidMw } from "../../src/middlewares/essence/CollectPaidMw.sol";
import { CollectDisallowedMw } from "../../src/middlewares/essence/CollectDisallowedMw.sol";
import { CollectOnlySubscribedMw } from "../../src/middlewares/essence/CollectOnlySubscribedMw.sol";
import { CollectMerkleDropMw } from "../../src/middlewares/essence/CollectMerkleDropMw.sol";
import { Create2Deployer } from "../../src/deployer/Create2Deployer.sol";
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
        address cyberBox;
    }
    struct DeployParams {
        bool isDeploy;
        bool writeFile; // write deployed contract addresses to file in deployment flow
        DeploySetting.DeployParameters setting; // passed in from deploy script or filled with test settings
    }

    // link3 specific setting
    string internal constant LINK3_NAME = "Link3";
    string internal constant LINK3_SYMBOL = "LINK3";
    bytes32 constant LINK3_SALT = keccak256(bytes("Link3"));

    // set engine owner to zero and let engine role authority handle access control
    address internal constant ENGINE_OWNER = address(0);

    // create2 deploy all contract with this protocol salt
    bytes32 constant SALT = keccak256(bytes("CCV2SALT"));

    // Initial States
    uint256 internal constant _INITIAL_FEE_FREE = 0 ether;
    uint256 internal constant _INITIAL_FEE_TIER0 = 10 ether;
    uint256 internal constant _INITIAL_FEE_TIER1 = 2 ether;
    uint256 internal constant _INITIAL_FEE_TIER2 = 1 ether;
    uint256 internal constant _INITIAL_FEE_TIER3 = 0.5 ether;
    uint256 internal constant _INITIAL_FEE_TIER4 = 0.1 ether;
    uint256 internal constant _INITIAL_FEE_TIER5 = 0.05 ether;
    uint256 internal constant _INITIAL_FEE_TIER6 = 0.01 ether;

    uint256 internal constant _INITIAL_USD_FEE_FREE = 0;
    uint256 internal constant _INITIAL_USD_FEE_TIER0 = 10000;
    uint256 internal constant _INITIAL_USD_FEE_TIER1 = 2000;
    uint256 internal constant _INITIAL_USD_FEE_TIER2 = 1000;
    uint256 internal constant _INITIAL_USD_FEE_TIER3 = 500;
    uint256 internal constant _INITIAL_USD_FEE_TIER4 = 100;
    uint256 internal constant _INITIAL_USD_FEE_TIER5 = 50;
    uint256 internal constant _INITIAL_USD_FEE_TIER6 = 10;
    uint256 internal constant _INITIAL_USD_FEE_TIER7 = 1;

    string internal constant OUTPUT_FILE = "docs/deploy/";

    function _fileName() internal view returns (string memory) {
        uint256 chainId = block.chainid;
        string memory chainName;
        if (chainId == 1) chainName = "mainnet";
        else if (chainId == 3) chainName = "ropsten";
        else if (chainId == 4) chainName = "rinkeby";
        else if (chainId == 5) chainName = "goerli";
        else if (chainId == 42) chainName = "kovan";
        else if (chainId == 97) chainName = "bnbt";
        else if (chainId == 56) chainName = "bnb";
        else if (chainId == 31337) chainName = "anvil";
        else if (chainId == 42170) chainName = "nova";
        else if (chainId == 137) chainName = "polygon";
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
                address(0),
                engineTreasury
            );
        DeployParams memory params = DeployParams(false, false, setting);
        addrs = deploy(
            vm,
            params,
            address(0x1890) // any EOA address to receive a link3 profile
        );

        Create2Deployer dc = new Create2Deployer();
        (, addrs.link3DescriptorProxy) = deployLink3Descriptor(
            vm,
            address(dc),
            false,
            "testurl",
            addrs.link3Profile,
            address(this)
        );

        (, addrs.cyberBox) = deployBox(vm, address(dc), address(this), false);
    }

    function deploy(
        Vm vm,
        DeployParams memory params,
        address mintToEOA
    ) internal returns (ContractAddresses memory addrs) {
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
        if (
            block.chainid == 31337 || block.chainid == 97 || block.chainid == 5
        ) {
            LibDeploy.registerLink3TestProfile(
                vm,
                RegisterLink3TestProfileParams(
                    addrs.link3Profile,
                    addrs.engineProxyAddress,
                    addrs.link3ProfileMw,
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

    function deployGrand(
        Vm vm,
        address dc,
        address link3Owner,
        address link3Signer,
        bool writeFile
    ) internal returns (address grandImpl, address grandProxy) {
        grandImpl = Create2Deployer(dc).deploy(
            type(CyberGrandNFT).creationCode,
            SALT
        );
        if (writeFile) {
            _write(vm, "CyberGrandNFT (Impl)", grandImpl);
        }

        bytes memory _data = abi.encodeWithSelector(
            CyberGrandNFT.initialize.selector,
            link3Owner,
            link3Signer,
            "Connect2022 Grand NFT",
            "GRAND_NFT",
            "https://metadata.cyberconnect.dev/grandnft.json"
        );
        grandProxy = Create2Deployer(dc).deploy(
            abi.encodePacked(
                type(ERC1967Proxy).creationCode,
                abi.encode(grandImpl, _data)
            ),
            SALT
        );
        if (writeFile) {
            _write(vm, "CyberGrandNFT (Proxy)", grandProxy);
        }
        require(
            CyberGrandNFT(grandProxy).paused() == true,
            "GRAND_NFT_NOT_PAUSED"
        );

        require(
            CyberGrandNFT(grandProxy).getSigner() == link3Signer,
            "WRONG_SIGNER"
        );
    }

    function deployMB(
        Vm vm,
        address dc,
        address link3Owner,
        address boxAddr,
        bool writeFile
    ) internal {
        address MBImpl = Create2Deployer(dc).deploy(
            type(MBNFT).creationCode,
            SALT
        );

        if (writeFile) {
            _write(vm, "MBNFT (Impl)", MBImpl);
        }

        bytes memory _dataMB = abi.encodeWithSelector(
            MBNFT.initialize.selector,
            link3Owner,
            boxAddr,
            "The Shards",
            "SHARDS",
            "https://mbmetadata.cyberconnect.dev"
        );

        address MBProxy = Create2Deployer(dc).deploy(
            abi.encodePacked(
                type(ERC1967Proxy).creationCode,
                abi.encode(MBImpl, _dataMB)
            ),
            SALT
        );
        if (writeFile) {
            _write(vm, "MBNFT (Proxy)", MBProxy);
        }

        require(MBNFT(MBProxy).paused() == false, "MB_NFT_PAUSED");
        require(MBNFT(MBProxy).getBoxAddr() == boxAddr, "WRONG_BOX_ADDR");
    }

    function deployFrame(
        Vm vm,
        address dc,
        address link3Signer,
        bool writeFile
    ) internal returns (address frame) {
        Create2Deployer dc = Create2Deployer(dc);
        frame = dc.deploy(
            abi.encodePacked(
                type(FrameNFT).creationCode,
                abi.encode(
                    "https://mbmetadata.cyberconnect.dev/frames",
                    link3Signer
                )
            ),
            SALT
        );
        if (writeFile) {
            _write(vm, "FrameNFT", frame);
        }
    }

    function deployVault(
        Vm vm,
        DeployParams memory params,
        address vaultOwner,
        bool writeFile
    ) internal returns (address vault) {
        Create2Deployer dc = Create2Deployer(params.setting.deployerContract);
        vault = dc.deploy(
            abi.encodePacked(
                type(CyberVault).creationCode,
                abi.encode(vaultOwner)
            ),
            SALT
        );
        if (writeFile) {
            _write(vm, "CyberVault", vault);
        }
        require(CyberVault(vault).getSigner() == vaultOwner, "WRONG_SIGNER");
    }

    function deployRelationshipChecker(
        Vm vm,
        DeployParams memory params,
        address namespace,
        bool writeFile
    ) internal returns (address checker) {
        Create2Deployer dc = Create2Deployer(params.setting.deployerContract);
        checker = dc.deploy(
            abi.encodePacked(
                type(RelationshipChecker).creationCode,
                abi.encode(namespace)
            ),
            SALT
        );

        if (writeFile) {
            _write(vm, "RelationshipChecker", checker);
        }
    }

    function deployCyberToken(
        Vm vm,
        address tokenOwner,
        address to,
        bool writeFile
    ) internal returns (address token) {
        token = address(new CYBER(tokenOwner, to));
        if (writeFile) {
            _write(vm, "CyberToken", token);
        }
        require(CYBER(token).owner() == tokenOwner, "WRONG_OWNER");
    }

    function deployTimeLock(
        Vm vm,
        address owner,
        uint256 minDeplay,
        bool writeFile
    ) internal returns (address lock) {
        address[] memory proposers = new address[](1);
        proposers[0] = owner;
        address[] memory executors = new address[](1);
        executors[0] = owner;

        lock = address(new TimelockController(minDeplay, proposers, executors));
        if (writeFile) {
            _write(vm, "Timelock", lock);
        }
    }

    function deployActionLib(
        Vm vm,
        address dc,
        bool writeFile
    ) internal {
        address actionLib = Create2Deployer(dc).deploy(
            type(Actions).creationCode,
            SALT
        );
        console.logBytes(type(Actions).creationCode);
        if (writeFile) {
            _write(vm, "Action Lib", actionLib);
        }
    }

    function changeOwnership(
        Vm vm,
        address timelock,
        address engineGov,
        address engineAuthority,
        address boxProxy,
        address link3DescriptorProxy,
        address cyberConnectTreasury
    ) internal {
        // CyberEngine set gov role to timelock
        RolesAuthority(engineAuthority).setUserRole(
            engineGov,
            Constants._ENGINE_GOV_ROLE,
            false
        );
        RolesAuthority(engineAuthority).setUserRole(
            timelock,
            Constants._ENGINE_GOV_ROLE,
            true
        );

        // EngineAuthority owner role change to timelock
        // bytes memory methodData = abi.encodeWithSignature("setOwner(address)", address(0xA7b6bEf855c1c57Df5b7C9c7a4e1eB757e544e7f));
        // console.logBytes(methodData);
        RolesAuthority(engineAuthority).setOwner(timelock);
        require(
            RolesAuthority(engineAuthority).owner() == timelock,
            "WRONG_ENGINE_AUTH_OWNER"
        );

        // CyberBox owner role change to timelock
        CyberBoxNFT(boxProxy).setOwner(timelock);
        require(CyberBoxNFT(boxProxy).owner() == timelock, "WRONG_BOX_OWNER");

        // Link3Descriptor owner role change to timelock
        Link3ProfileDescriptor(link3DescriptorProxy).setOwner(timelock);
        require(
            Link3ProfileDescriptor(link3DescriptorProxy).owner() == timelock,
            "WRONG_DESC_OWNER"
        );

        // CyberConnect treasury owner role change to timelock
        Treasury(cyberConnectTreasury).setOwner(timelock);
        require(
            Treasury(cyberConnectTreasury).owner() == timelock,
            "WRONG_TREASURY_OWNER"
        );
    }

    function deployAllMiddleware(
        Vm vm,
        DeployParams memory params,
        address engine,
        address cyberTreasury,
        address usdOracle,
        bool writeFile
    ) internal returns (address token) {
        Create2Deployer dc = Create2Deployer(params.setting.deployerContract); // for deployment
        address mw;

        // // CollectPermissionMw
        // mw = dc.deploy(
        //     abi.encodePacked(type(CollectPermissionMw).creationCode),
        //     SALT
        // );

        // if (writeFile) {
        //     _write(vm, "Essence MW (CollectPermissionMw V2)", mw);
        // }

        // CyberEngine(engine).allowEssenceMw(mw, true);

        // // SubscribePaidMw
        // mw = dc.deploy(
        //     abi.encodePacked(
        //         type(SubscribePaidMw).creationCode,
        //         abi.encode(cyberTreasury)
        //     ),
        //     SALT
        // );

        // if (writeFile) {
        //     _write(vm, "Subscribe MW (SubscribePaidMw)", mw);
        // }

        // CyberEngine(engine).allowSubscribeMw(mw, true);

        // // SubscribeOnlyOnceMw
        // mw = dc.deploy(
        //     abi.encodePacked(type(SubscribeOnlyOnceMw).creationCode),
        //     SALT
        // );

        // if (writeFile) {
        //     _write(vm, "Subscribe MW (SubscribeOnlyOnceMw)", mw);
        // }

        // // SubscribeDisallowedMw
        // mw = dc.deploy(
        //     abi.encodePacked(type(SubscribeDisallowedMw).creationCode),
        //     SALT
        // );

        // if (writeFile) {
        //     _write(vm, "Subscribe MW (SubscribeDisallowedMw)", mw);
        // }

        // CyberEngine(engine).allowSubscribeMw(mw, true);

        // // CollectPaidMw
        // mw = dc.deploy(
        //     abi.encodePacked(
        //         type(CollectPaidMw).creationCode,
        //         abi.encode(cyberTreasury)
        //     ),
        //     SALT
        // );

        // if (writeFile) {
        //     _write(vm, "Essence MW (CollectPaidMw)", mw);
        // }

        // CyberEngine(engine).allowEssenceMw(mw, true);

        // // CollectDisallowedMw
        // mw = dc.deploy(
        //     abi.encodePacked(type(CollectDisallowedMw).creationCode),
        //     SALT
        // );

        // if (writeFile) {
        //     _write(vm, "Essence MW (CollectDisallowedMw)", mw);
        // }

        // CyberEngine(engine).allowEssenceMw(mw, true);

        // // CollectOnlySubscribedMw
        // mw = dc.deploy(
        //     abi.encodePacked(type(CollectOnlySubscribedMw).creationCode),
        //     SALT
        // );

        // if (writeFile) {
        //     _write(vm, "Essence MW (CollectOnlySubscribedMw)", mw);
        // }

        // CyberEngine(engine).allowEssenceMw(mw, true);

        // // CollectMerkleDropMw
        // mw = dc.deploy(
        //     abi.encodePacked(type(CollectMerkleDropMw).creationCode),
        //     SALT
        // );

        // if (writeFile) {
        //     _write(vm, "Essence MW (CollectMerkleDropMw)", mw);
        // }

        // CyberEngine(engine).allowEssenceMw(mw, true);

        // StableFeeCreationMw
        // mw = dc.deploy(
        //     abi.encodePacked(
        //         type(StableFeeCreationMw).creationCode,
        //         abi.encode(engine, usdOracle)
        //     ),
        //     SALT
        // );

        // if (writeFile) {
        //     _write(vm, "Profile MW (StableFeeCreationMw)", mw);
        // }

        // OP set
        // mw = address(0xE5B8C70427c25365A62648f8804C5eAeE57Fb006);
        // bytes memory methodData = abi.encodeWithSignature("allowProfileMw(address,bool)", mw, true);
        // console.logBytes(methodData);

        // require(
        //     CyberEngine(engine).isProfileMwAllowed(mw) ==
        //         true,
        //     "MW_NOT_ALLOWED"
        // );

        //CyberEngine(engine).allowProfileMw(mw, true);
    }

    function allowCurrency(
        Vm vm,
        address treasury,
        address currencyAddr
    ) internal {
        Treasury(treasury).allowCurrency(currencyAddr, true);
        require(
            Treasury(treasury).isCurrencyAllowed(currencyAddr) == true,
            "CURRENCY_NOT_ALLOWED"
        );
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
        RolesAuthority(addrs.engineAuthority).setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            addrs.engineProxyAddress,
            CyberEngine.upgradeProfileNFT.selector,
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
                _INITIAL_FEE_FREE,
                _INITIAL_FEE_FREE,
                _INITIAL_FEE_FREE,
                _INITIAL_FEE_FREE,
                _INITIAL_FEE_FREE,
                _INITIAL_FEE_FREE,
                _INITIAL_FEE_FREE
            )
        );
    }

    function setProfileMw(
        Vm vm,
        DeployParams memory params,
        address engineProxyAddress,
        address link3Profile,
        address link3ProfileMw
    ) internal returns (address token) {
        // CyberEngine(engineProxyAddress).setProfileMw(
        //     link3Profile,
        //     link3ProfileMw,
        //     abi.encode(
        //         params.setting.link3Signer,
        //         params.setting.link3Treasury,
        //         _INITIAL_FEE_TIER0,
        //         _INITIAL_FEE_TIER1,
        //         _INITIAL_FEE_TIER2,
        //         _INITIAL_FEE_TIER3,
        //         _INITIAL_FEE_TIER4,
        //         _INITIAL_FEE_TIER5,
        //         _INITIAL_FEE_TIER6
        //     )
        // );

        CyberEngine(engineProxyAddress).setProfileMw(
            link3Profile,
            link3ProfileMw,
            abi.encode(
                params.setting.link3Signer,
                params.setting.link3Treasury,
                _INITIAL_FEE_FREE,
                _INITIAL_FEE_FREE,
                _INITIAL_FEE_FREE,
                _INITIAL_FEE_FREE,
                _INITIAL_FEE_FREE,
                _INITIAL_FEE_FREE,
                _INITIAL_FEE_FREE
            )
        );
        require(
            PermissionedFeeCreationMw(link3ProfileMw).getSigner(link3Profile) ==
                params.setting.link3Signer,
            "LINK3_SIGNER_WRONG"
        );
    }

    function setStableFeeMw(
        Vm vm,
        DeployParams memory params,
        address engineProxyAddress,
        address link3Profile,
        address stableFeeMw
    ) internal returns (address token) {
        // CyberEngine(engineProxyAddress).setProfileMw(
        //     link3Profile,
        //     stableFeeMw,
        //     abi.encode(
        //         params.setting.link3Signer,
        //         params.setting.link3Treasury,
        //         _INITIAL_USD_FEE_TIER0,
        //         _INITIAL_USD_FEE_TIER1,
        //         _INITIAL_USD_FEE_TIER2,
        //         _INITIAL_USD_FEE_TIER3,
        //         _INITIAL_USD_FEE_TIER4,
        //         _INITIAL_USD_FEE_TIER5,
        //         _INITIAL_USD_FEE_TIER6,
        //         _INITIAL_USD_FEE_TIER7
        //     )
        // );
        // require(
        //     StableFeeCreationMw(stableFeeMw).getSigner(link3Profile) ==
        //         params.setting.link3Signer,
        //     "LINK3_SIGNER_WRONG"
        // );
        // bytes memory methodData = abi.encodeWithSignature("setProfileMw(address,address,bytes)", link3Profile, stableFeeMw, abi.encode(
        //         params.setting.link3Signer,
        //         params.setting.link3Treasury,
        //         _INITIAL_USD_FEE_TIER0,
        //         _INITIAL_USD_FEE_TIER1,
        //         _INITIAL_USD_FEE_TIER2,
        //         _INITIAL_USD_FEE_TIER3,
        //         _INITIAL_USD_FEE_TIER4,
        //         _INITIAL_USD_FEE_TIER5,
        //         _INITIAL_USD_FEE_TIER6,
        //         _INITIAL_USD_FEE_TIER7
        //     ));
        // console.logBytes(methodData);
        // uint256 fee = StableFeeCreationMw(stableFeeMw).getPriceWei(
        //     link3Profile,
        //     "ABCDDDSASDSSSDD"
        // );
        // console.log(fee);
    }

    function setAniURL(
        Vm vm,
        DeployParams memory params,
        address link3Desc
    ) internal {
        string
            memory preURL = "https://cyberconnect.mypinata.cloud/ipfs/bafkreidztiie5tmfvadt52nnb4q2g2whglrnsyhyk7d43hwczh65xjtwni";
        string
            memory newURL = "https://cyberconnect.mypinata.cloud/ipfs/bafkreigjfjobgbh6voodb4z4u3nfpuchwb5usolon6i67kecelki2uzb6y";
        string memory pre = Link3ProfileDescriptor(link3Desc)
            .animationTemplate();
        console.log(pre);
        require(
            keccak256(
                abi.encodePacked(
                    Link3ProfileDescriptor(link3Desc).animationTemplate()
                )
            ) == keccak256(abi.encodePacked(preURL)),
            "WRONG_ANI_URL"
        );

        Link3ProfileDescriptor(link3Desc).setAnimationTemplate(newURL);
        require(
            keccak256(
                abi.encodePacked(
                    Link3ProfileDescriptor(link3Desc).animationTemplate()
                )
            ) == keccak256(abi.encodePacked(newURL)),
            "WRONG_CUR_ANI_URL"
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
        address profile;
        address engine;
        address mw;
        address mintToEOA;
        address link3Treasury;
        address engineTreasury;
    }

    // for testnet and test fixture
    function registerLink3TestProfile(
        Vm vm,
        RegisterLink3TestProfileParams memory params
    ) internal {
        address originSigner = PermissionedFeeCreationMw(params.mw).getSigner(
            params.profile
        );
        uint256 startingLink3 = params.link3Treasury.balance;
        uint256 startingEngine = params.engineTreasury.balance;
        address signer = vm.addr(TEST_SIGNER_PK);

        // change signer to tempory signer
        CyberEngine(params.engine).setProfileMw(
            params.profile,
            params.mw,
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
            PermissionedFeeCreationMw(params.mw).getSigner(params.profile) ==
                signer,
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
                params.mw,
                data,
                "PermissionedFeeCreationMw",
                "1"
            );
        }
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(TEST_SIGNER_PK, digest);

        require(
            PermissionedFeeCreationMw(params.mw).getNonce(
                params.profile,
                params.mintToEOA
            ) == 0
        );
        ProfileNFT(params.profile).createProfile{ value: _INITIAL_FEE_TIER6 }(
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
            PermissionedFeeCreationMw(params.mw).getNonce(
                params.profile,
                params.mintToEOA
            ) == 1
        );
        require(ProfileNFT(params.profile).balanceOf(params.mintToEOA) == 1);
        require(
            params.link3Treasury.balance == startingLink3 + 0.00975 ether,
            "LINK3_TREASURY_BALANCE_INCORRECT"
        );
        require(
            params.engineTreasury.balance == startingEngine + 0.00025 ether,
            "ENGINE_TREASURY_BALANCE_INCORRECT"
        );

        // revert signer
        CyberEngine(params.engine).setProfileMw(
            params.profile,
            params.mw,
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
    ) internal returns (address impl, address proxy) {
        Create2Deployer dc = Create2Deployer(_dc);
        impl = dc.deploy(
            abi.encodePacked(type(Link3ProfileDescriptor).creationCode),
            SALT
        );
        if (writeFile) {
            _write(vm, "Link3 Descriptor (Impl)", impl);
        }

        proxy = dc.deploy(
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
    }

    function deployLink3DescriptorV2(
        Vm vm,
        address _dc,
        bool writeFile,
        address link3Profile,
        address link3Owner
    ) internal returns (address impl, address proxy) {
        Create2Deployer dc = Create2Deployer(_dc);
        impl = dc.deploy(
            abi.encodePacked(type(Link3ProfileDescriptorV2).creationCode),
            SALT
        );
        if (writeFile) {
            _write(vm, "Link3 DescriptorV2 (Impl)", impl);
        }

        proxy = dc.deploy(
            abi.encodePacked(
                type(ERC1967Proxy).creationCode,
                abi.encode(
                    impl,
                    abi.encodeWithSelector(
                        Link3ProfileDescriptorV2.initialize.selector,
                        link3Owner
                    )
                )
            ),
            SALT
        );
        if (writeFile) {
            _write(vm, "Link3 DescriptorV2 (Proxy)", proxy);
        }

        // Need to have access to LINK3 OWNER
        ProfileNFT(link3Profile).setNFTDescriptor(proxy);

        require(
            ProfileNFT(link3Profile).getNFTDescriptor() == proxy,
            "NFT_DESCRIPTOR_NOT_SET"
        );
    }
}
