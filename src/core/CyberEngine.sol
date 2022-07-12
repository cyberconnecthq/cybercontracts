// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "../upgradeability/Initializable.sol";
import { ICyberEngine } from "../interfaces/ICyberEngine.sol";
import { ProfileNFT } from "./ProfileNFT.sol";
import { IProfileMiddleware } from "../interfaces/IProfileMiddleware.sol";
import { IProfileDeployer } from "../interfaces/IProfileDeployer.sol";
import { ISubscribeDeployer } from "../interfaces/ISubscribeDeployer.sol";
import { IEssenceDeployer } from "../interfaces/IEssenceDeployer.sol";
import { Auth, Authority } from "../dependencies/solmate/Auth.sol";
import { RolesAuthority } from "../dependencies/solmate/RolesAuthority.sol";
import { DataTypes } from "../libraries/DataTypes.sol";
import { Constants } from "../libraries/Constants.sol";
import { CyberEngineStorage } from "../storages/CyberEngineStorage.sol";
import { IUpgradeable } from "../interfaces/IUpgradeable.sol";
import { UpgradeableBeacon } from "../upgradeability/UpgradeableBeacon.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title CyberEngine
 * @author CyberConnect
 * @notice This is the main entry point for the CyberConnect contract.
 */
contract CyberEngine is
    Initializable,
    Auth,
    UUPSUpgradeable,
    CyberEngineStorage,
    IUpgradeable,
    ICyberEngine
{
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the CyberEngine.
     *
     * @param _owner Owner to set for CyberEngine.
     * @param _rolesAuthority RolesAuthority address to manage access control
     */
    function initialize(address _owner, RolesAuthority _rolesAuthority)
        external
        initializer
    {
        Auth.__Auth_Init(_owner, _rolesAuthority);
    }

    function setProfileMw(
        address namespace,
        address mw,
        bytes calldata data
    ) external requiresAuth {
        require(
            mw == address(0) || _profileMwAllowlist[mw],
            "PROFILE_MW_NOT_ALLOWED"
        );
        _namespaceInfo[namespace].profileMw = mw;
        bytes memory returnData;
        if (mw != address(0)) {
            returnData = IProfileMiddleware(mw).setProfileMwData(
                namespace,
                data
            );
        }
        emit SetProfileMw(namespace, mw, returnData);
    }

    function isProfileMwAllowed(address mw) external view returns (bool) {
        return _profileMwAllowlist[mw];
    }

    // TODO: maybe separate
    function getNamespaceData(address namespace)
        external
        view
        returns (DataTypes.NamespaceStruct memory)
    {
        return _namespaceInfo[namespace];
    }

    /**
     * @notice Allows the profile middleware.
     *
     * @param mw The middleware address.
     * @param allowed The allowance state.
     */
    function allowProfileMw(address mw, bool allowed) external requiresAuth {
        bool preAllowed = _profileMwAllowlist[mw];
        _profileMwAllowlist[mw] = allowed;
        emit AllowProfileMw(mw, preAllowed, allowed);
    }

    function createNamespace(DataTypes.CreateNamespaceParams calldata params)
        external
        requiresAuth
        returns (address)
    {
        bytes memory byteName = bytes(params.name);
        bytes memory byteSymbol = bytes(params.symbol);

        bytes32 salt = keccak256(byteName);

        require(
            _namespaceByName[salt] == address(0),
            "NAMESPACE_ALREADY_EXISTS"
        );

        require(
            byteName.length <= Constants._MAX_NAMESPACE_LENGTH,
            "NAME_INVALID_LENGTH"
        );
        require(
            byteSymbol.length <= Constants._MAX_SYMBOL_LENGTH,
            "SYMBOL_INVALID_LENGTH"
        );

        // todo delete authority from init
        bytes memory data = abi.encodeWithSelector(
            ProfileNFT.initialize.selector,
            address(0),
            params.name,
            params.symbol,
            params.descriptor,
            address(0)
        );

        ISubscribeDeployer(params.addrs.subscribeFactory).deploy(salt);
        IEssenceDeployer(params.addrs.essenceFactory).deploy(salt);

        new UpgradeableBeacon{ salt: salt }(
            params.addrs.subscribeImpl,
            params.owner
        );
        new UpgradeableBeacon{ salt: salt }(
            params.addrs.essenceImpl,
            params.owner
        );

        IProfileDeployer(params.addrs.profileFactory).deploy(salt);
        address actualProfileProxy = address(
            new ERC1967Proxy{ salt: salt }(params.addrs.profileImpl, data)
        );
        require(
            actualProfileProxy == params.addrs.profileProxy,
            "PROFILE_PROXY_WRONG_ADDRESS"
        );

        _namespaceInfo[params.addrs.profileProxy].name = params.name;
        _namespaceInfo[params.addrs.profileProxy].owner = params.owner;

        // TODO emit event
        _namespaceByName[salt] = params.addrs.profileProxy;
        return params.addrs.profileProxy;
    }

    /**
     * @notice Contract version number.
     *
     * @return uint256 The version number.
     * @dev This contract can be upgraded with UUPS upgradeability
     */
    function version() external pure virtual override returns (uint256) {
        return _VERSION;
    }

    // UUPS upgradeability
    function _authorizeUpgrade(address) internal override canUpgrade {}

    /**
     * @notice Checks if the sender is authorized to upgrade the contract.
     */
    modifier canUpgrade() {
        require(
            isAuthorized(msg.sender, Constants._AUTHORIZE_UPGRADE),
            "UNAUTHORIZED"
        );

        _;
    }
}
