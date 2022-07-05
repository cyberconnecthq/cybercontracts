// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface ICyberEngineEvents {
    /**
     * @dev Emitted when the CyberEngine is initialized.
     *
     * @param owner Owner to set for CyberEngine.
     * @param profileAddress Profile address to set for CyberEngine.
     * @param boxAddress Box Address animation url to set for CyberEngine.
     * @param subscribeNFTBeacon Subscribe NFT beacon to set for CyberEngine.
     */
    event Initialize(
        address indexed owner,
        address profileAddress,
        address boxAddress,
        address subscribeNFTBeacon
    );

    /**
     * @dev Emitted when a new signer has been set.
     *
     * @param preSigner The previous signer address.
     * @param newSigner The newly set signer address.
     */
    event SetSigner(address indexed preSigner, address indexed newSigner);

    /**
     * @dev Emitted when a new profile address has been set.
     *
     * @param preProfileAddr The previous profile address.
     * @param newProfileAddr The newly set profile address.
     */
    event SetProfileAddress(
        address indexed preProfileAddr,
        address indexed newProfileAddr
    );

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
     * @notice Emitted when a new fee for tiers has been set.
     *
     * @param tier The tier number.
     * @param preAmount The previous fee amount.
     * @param newAmount The newly set fee amount.
     */
    event SetFeeByTier(
        DataTypes.Tier indexed tier,
        uint256 indexed preAmount,
        uint256 indexed newAmount
    );

    /**
     * @notice Emitted when the box giveaway state has been set to `ended`.
     *
     * @param preEnded The previous box giveaway state.
     * @param newEnded The newly set box giveaway state.
     */
    event SetBoxGiveawayEnded(bool indexed preEnded, bool indexed newEnded);

    /**
     * @notice Emitted when a new state has been set.
     *
     * @param preState The previous state.
     * @param newState The newly set state.
     */
    event SetState(
        DataTypes.State indexed preState,
        DataTypes.State indexed newState
    );

    /**
     * @notice Emitted when a new animation template has been set.
     *
     * @param newTemplate The newly set animation template.
     */
    event SetAnimationTemplate(string indexed newTemplate);

    /**
     * @notice Emitted when a new image template has been set.
     *
     * @param newTemplate The newly set image template.
     */
    event SetImageTemplate(string indexed newTemplate);

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
     * @notice Emitted when the operator approval has been set.
     *
     * @param profileId The profile id.
     * @param operator The operator address.
     * @param approved The newly set bool value for operator approval.
     */
    event SetOperatorApproval(
        uint256 indexed profileId,
        address indexed operator,
        bool indexed approved
    );

    /**
     * @notice Emitted when a new registration been created.
     *
     * @param to The receiver address.
     * @param profileId The newly generated profile id.
     * @param handle The newly set handle.
     * @param avatar The newly set avatar.
     * @param metadata The newly set metadata.
     */
    event Register(
        address indexed to,
        uint256 indexed profileId,
        string handle,
        string avatar,
        string metadata
    );

    /**
     * @notice Emitted when a profile claims a box nft.
     *
     * @param to The claimer address.
     * @param boxId The box id that has been claimed.
     */
    event ClaimBox(address indexed to, uint256 indexed boxId);

    /**
     * @notice Emitted when an address has withdrawed.
     *
     * @param to The receiver address.
     * @param amount The amount sent.
     */
    event Withdraw(address indexed to, uint256 indexed amount);

    /**
     * @notice Emitted when a subscription has been created.
     *
     * @param sender The sender address.
     * @param profileIds The profile ids subscribed to.
     * @param subDatas The subscription data set.
     */
    event Subscribe(
        address indexed sender,
        uint256[] profileIds,
        bytes[] subDatas
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
     * @notice Emitted when a subscription middleware has been set to a profile.
     *
     * @param profileId The profile id.
     * @param preMw The previous middleware.
     * @param newMw The newly set middleware.
     */
    event SetSubscribeMw(
        uint256 indexed profileId,
        address preMw,
        address newMw
    );

    /**
     * @notice Emitted when a new subscribe nft has been deployed.
     *
     * @param profileId The profile id.
     * @param subscribeNFT The newly deployed subscribe nft address.
     */
    event DeploySubscribeNFT(
        uint256 indexed profileId,
        address indexed subscribeNFT
    );
}
