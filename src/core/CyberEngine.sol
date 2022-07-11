// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "../upgradeability/Initializable.sol";
import { ICyberEngine } from "../interfaces/ICyberEngine.sol";
import { IProfileMiddleware } from "../interfaces/IProfileMiddleware.sol";
import { ProfileNFT } from "./ProfileNFT.sol";
import { SubscribeNFT } from "./SubscribeNFT.sol";
import { EssenceNFT } from "./EssenceNFT.sol";
import { ProfileRoles } from "./ProfileRoles.sol";
import { Auth, Authority } from "../dependencies/solmate/Auth.sol";
import { RolesAuthority } from "../dependencies/solmate/RolesAuthority.sol";
import { DataTypes } from "../libraries/DataTypes.sol";
import { Constants } from "../libraries/Constants.sol";
import { ERC721 } from "../dependencies/solmate/ERC721.sol";
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
        require(_profileMwAllowlist[mw], "PROFILE_MW_NOT_ALLOWED");
        address preMw = _namespaceInfo[namespace].profileMw;
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
    {
        bytes memory byteName = bytes(params.name);
        bytes memory byteSymbol = bytes(params.symbol);

        require(
            _profileMwAllowlist[params.mw] || params.mw == address(0),
            "PROFILE_MW_NOT_ALLOWED"
        );
        require(
            byteName.length <= Constants._MAX_NAMESPACE_LENGTH,
            "NAME_INVALID_LENGTH"
        );
        require(
            byteSymbol.length <= Constants._MAX_SYMBOL_LENGTH,
            "SYMBOL_INVALID_LENGTH"
        );

        // TODO delete and re-think about our proxy addreess calulation logic
        // bytes data = 
        address profileProxy = _computeAddress(
            abi.encode(type(ERC1967Proxy).creationCode),
            _salt
        );
        address authority = new RolesAuthority(
            params.owner,
            Authority(address(0))
        );
        address subscribeImpl = new SubscribeNFT(profileProxy);
        address essenceImpl = new EssenceNFT(profileProxy);
        address subscribeBeacon = new UpgradeableBeacon(
            subscribeImpl,
            params.owner
        );

        address essenceBeacon = new UpgradeableBeacon(
            subscribeImpl,
            params.owner
        );

        address profileImpl = new ProfileNFT(subscribeBeacon, essenceBeacon);

        new ERC1967Proxy(
            profileImpl,
            abi.encodeWithSelector(
                ProfileNFT.initialize.selector,
                address(0),
                params.name,
                params.symbol,
                params.descriptor,
                authority
            )
        );

        _namespaceInfo[profileProxy].name = params.name;
        _namespaceInfo[profileProxy].profileMw = params.mw;
        _namespaceInfo[profileProxy].owner = params.owner;

        // TODO emit event
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

    function _computeAddress(bytes memory _byteCode, uint256 _salt)
        internal
        view
        returns (address)
    {
        bytes32 hash_ = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                _salt,
                keccak256(_byteCode)
            )
        );
        return address(uint160(uint256(hash_)));
    }
}
