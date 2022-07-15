// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { Auth, Authority } from "../dependencies/solmate/Auth.sol";
import { RolesAuthority } from "../dependencies/solmate/RolesAuthority.sol";

import { ICyberEngine } from "../interfaces/ICyberEngine.sol";
import { IProfileMiddleware } from "../interfaces/IProfileMiddleware.sol";
import { IProfileDeployer } from "../interfaces/IProfileDeployer.sol";
import { ISubscribeDeployer } from "../interfaces/ISubscribeDeployer.sol";
import { IEssenceDeployer } from "../interfaces/IEssenceDeployer.sol";
import { IUpgradeable } from "../interfaces/IUpgradeable.sol";

import { Constants } from "../libraries/Constants.sol";
import { DataTypes } from "../libraries/DataTypes.sol";

import { ProfileNFT } from "./ProfileNFT.sol";
import { CyberEngineStorage } from "../storages/CyberEngineStorage.sol";
import { UpgradeableBeacon } from "../upgradeability/UpgradeableBeacon.sol";
import { Initializable } from "../upgradeability/Initializable.sol";

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
    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

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

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

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

    /**
     * @notice Allows the subscriber middleware.
     *
     * @param mw The middleware address.
     * @param allowed The allowance state.
     */
    function allowSubscribeMw(address mw, bool allowed) external requiresAuth {
        bool preAllowed = _subscribeMwAllowlist[mw];
        _subscribeMwAllowlist[mw] = allowed;
        emit AllowSubscribeMw(mw, preAllowed, allowed);
    }

    /**
     * @notice Allows the essence middleware.
     *
     * @param mw The middleware address.
     * @param allowed The allowance state.
     */
    function allowEssenceMw(address mw, bool allowed) external requiresAuth {
        bool preAllowed = _essenceMwAllowlist[mw];
        _essenceMwAllowlist[mw] = allowed;
        emit AllowEssenceMw(mw, preAllowed, allowed);
    }

    /**
     * @notice Creates a new namespace.
     *
     * @param params The namespace params:
     *  name: The namespace name.
     *  symbol: The namespace symbol.
     *  owner: The namespace owner.
     * @param profileProxy The profile proxy address.
     */
    function createNamespace(DataTypes.CreateNamespaceParams calldata params)
        external
        requiresAuth
        returns (address profileProxy)
    {
        bytes memory byteName = bytes(params.name);
        bytes memory byteSymbol = bytes(params.symbol);

        bytes32 salt = keccak256(byteName);

        require(
            _namespaceByName[salt] == address(0),
            "NAMESPACE_ALREADY_EXISTS"
        );

        require(
            byteName.length <= Constants._MAX_NAME_LENGTH,
            "NAME_INVALID_LENGTH"
        );
        require(
            byteSymbol.length <= Constants._MAX_SYMBOL_LENGTH,
            "SYMBOL_INVALID_LENGTH"
        );

        _namespaceInfo[params.addrs.profileProxy].name = params.name;
        _namespaceByName[salt] = params.addrs.profileProxy;

        {
            address subscribeImpl = ISubscribeDeployer(
                params.addrs.subscribeFactory
            ).deploySubscribe(salt, params.addrs.profileProxy);

            address essImpl = IEssenceDeployer(params.addrs.essenceFactory)
                .deployEssence(salt, params.addrs.profileProxy);

            address subBeacon = address(
                new UpgradeableBeacon{ salt: salt }(
                    subscribeImpl,
                    address(this)
                )
            );
            address essBeacon = address(
                new UpgradeableBeacon{ salt: salt }(essImpl, address(this))
            );

            address profileImpl = IProfileDeployer(params.addrs.profileFactory)
                .deployProfile(salt, address(this), subBeacon, essBeacon);

            bytes memory data = abi.encodeWithSelector(
                ProfileNFT.initialize.selector,
                params.owner,
                params.name,
                params.symbol
            );

            profileProxy = address(
                new ERC1967Proxy{ salt: salt }(profileImpl, data)
            );
        }
        require(
            profileProxy == params.addrs.profileProxy,
            "PROFILE_PROXY_WRONG_ADDRESS"
        );

        emit CreateNamespace(profileProxy, params.name, params.symbol);
    }

    /**
     * @notice Sets the profile middleware.
     *
     * @param namespace The namespace address.
     * @param mw The middleware address.
     * @param data The middleware data.
     * @dev the profile middleware needs to be allowed first.
     */
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

    /// @inheritdoc ICyberEngine
    function isEssenceMwAllowed(address mw)
        external
        view
        override
        returns (bool)
    {
        return _essenceMwAllowlist[mw];
    }

    /// @inheritdoc ICyberEngine
    function isSubscribeMwAllowed(address mw)
        external
        view
        override
        returns (bool)
    {
        return _subscribeMwAllowlist[mw];
    }

    /// @inheritdoc ICyberEngine
    function isProfileMwAllowed(address mw)
        external
        view
        override
        returns (bool)
    {
        return _profileMwAllowlist[mw];
    }

    /// @inheritdoc ICyberEngine
    function getNameByNamespace(address namespace)
        external
        view
        override
        returns (string memory)
    {
        return _namespaceInfo[namespace].name;
    }

    /// @inheritdoc ICyberEngine
    function getProfileMwByNamespace(address namespace)
        external
        view
        override
        returns (address)
    {
        return _namespaceInfo[namespace].profileMw;
    }

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IUpgradeable
    function version() external pure virtual override returns (uint256) {
        return _VERSION;
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    // UUPS upgradeability
    function _authorizeUpgrade(address) internal override canUpgrade {}
}
