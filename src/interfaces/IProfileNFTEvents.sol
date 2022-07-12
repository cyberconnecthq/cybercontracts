// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface IProfileNFTEvents {
    /**
     * @dev Emitted when the CyberEngine is initialized.
     *
     * @param owner Owner to set for CyberEngine.
     */
    event Initialize(address indexed owner);

    /**
     * @dev Emitted when a new box address has been set.
     *
     * @param preBoxAddr The previous box address.
     * @param newBoxAddress The newly set box address.
     */
    event SetBoxAddress(
        address indexed preBoxAddr,
        address indexed newBoxAddress
    );

    /**
     * @notice Emitted when a new Profile NFT Descriptor has been set.
     *
     * @param newDescriptor The newly set descriptor address.
     */
    event SetNFTDescriptor(address indexed newDescriptor);

    /**
     * @notice Emitted when a new animation template has been set.
     *
     * @param newTemplate The newly set animation template.
     */
    event SetAnimationTemplate(string indexed newTemplate);

    /**
     * @notice Emitted when a new metadata has been set to a profile.
     *
     * @param profileId The profile id.
     * @param newMetadata The newly set metadata.
     */
    event SetMetadata(uint256 indexed profileId, string newMetadata);

    /**
     * @notice Emitted when a new avatar has been set to a profile.
     *
     * @param profileId The profile id.
     * @param newAvatar The newly set avatar.
     */
    event SetAvatar(uint256 indexed profileId, string indexed newAvatar);

    /**
     * @notice Emitted when a primary profile has been set.
     *
     * @param profileId The profile id.
     */
    event SetPrimaryProfile(address indexed user, uint256 indexed profileId);

    /**
     * @notice Emitted when the operator approval has been set.
     *
     * @param profileId The profile id.
     * @param operator The operator address.
     * @param prevApproved The previously set bool value for operator approval.
     * @param approved The newly set bool value for operator approval.
     */
    event SetOperatorApproval(
        uint256 indexed profileId,
        address indexed operator,
        bool prevApproved,
        bool approved
    );

    /**
     * @notice Emitted when a subscription middleware has been allowed.
     *
     * @param mw The middleware address.
     * @param preAllowed The previously allow state.
     * @param newAllowed The newly set allow state.
     */
    event AllowSubscribeMw(
        address indexed mw,
        bool indexed preAllowed,
        bool indexed newAllowed
    );

    /**
     * @notice Emitted when a essence middleware has been allowed.
     *
     * @param mw The middleware address.
     * @param preAllowed The previously allow state.
     * @param newAllowed The newly set allow state.
     */
    event AllowEssenceMw(
        address indexed mw,
        bool indexed preAllowed,
        bool indexed newAllowed
    );

    /**
     * @notice Emitted when a subscription middleware has been set to a profile.
     *
     * @param profileId The profile id.
     * @param mw The new middleware.
     * @param prepareReturnData The data used to prepare middleware.
     */
    event SetSubscribeMw(
        uint256 indexed profileId,
        address mw,
        bytes prepareReturnData
    );

    /**
     * @notice Emitted when a subscription middleware has been set to a profile.
     *
     * @param profileId The profile id.
     * @param subscribeTokenURI The token URI for subscribe NFT.
     */
    event SetSubscribeTokenURI(
        uint256 indexed profileId,
        string subscribeTokenURI
    );
}
