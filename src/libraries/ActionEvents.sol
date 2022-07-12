// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

library ActionEvents {
    /**
     * @notice Emitted when a new profile been created.
     *
     * @param to The receiver address.
     * @param profileId The newly generated profile id.
     * @param handle The newly set handle.
     * @param avatar The newly set avatar.
     * @param metadata The newly set metadata.
     */
    event CreateProfile(
        address indexed to,
        uint256 indexed profileId,
        string handle,
        string avatar,
        string metadata
    );

    /**
     * @notice Emitted when a primary profile has been set.
     *
     * @param profileId The profile id.
     */
    event SetPrimaryProfile(address indexed user, uint256 indexed profileId);

    event RegisterEssence(
        uint256 indexed profileId,
        uint256 indexed essenceId,
        string name,
        string symbol,
        string essenceTokenURI,
        address essenceMw,
        bytes prepareReturnData
    );

    /**
     * @notice Emitted when a subscription has been created.
     *
     * @param sender The sender address.
     * @param profileIds The profile ids subscribed to.
     * @param preDatas The subscription data for preprocess.
     * @param postDatas The subscription data for postprocess.
     */
    event Subscribe(
        address indexed sender,
        uint256[] profileIds,
        bytes[] preDatas,
        bytes[] postDatas
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

    /**
     * @notice Emitted when a new essence nft has been deployed.
     *
     * @param profileId The profile id.
     * @param essenceId The essence id.
     * @param essenceNFT The newly deployed subscribe nft address.
     */
    event DeployEssenceNFT(
        uint256 indexed profileId,
        uint256 indexed essenceId,
        address indexed essenceNFT
    );

    /**
     * @notice Emitted when a subscription has been created.
     *
     * @param collector The collector address.
     * @param profileId The profile ids subscribed to.
     * @param preData The subscription data for preprocess.
     * @param postData The subscription data for postprocess.
     */
    event CollectEssence(
        address indexed collector,
        uint256 profileId,
        bytes preData,
        bytes postData
    );
}
