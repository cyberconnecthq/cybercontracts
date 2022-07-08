// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface IProfileNFT {
    /**
     * @notice Creates a profile and mints it to the recipient address.
     *
     * @param params contains the recipient, handle, avatar and metadata.
     * @return uint256 profile id of the newly minted profile.
     *
     * @dev The current function validates the caller address and the handle before minting
     * and the following conditions must be met:
     * - The caller address must be the engine address.
     * - The recipient address must be a valid Ethereum address.
     * - The handle must contain only a-z, A-Z, 0-9.
     * - The handle must not be already used.
     * - The handle must not be longer than 27 bytes.
     * - The handle must not be empty.
     */
    function createProfile(DataTypes.CreateProfileParams calldata params)
        external
        returns (uint256, bool);

    /**
     * @notice Gets the profile handle by ID.
     *
     * @param profileId The profile ID.
     * @return memory the profile handle.
     */
    function getHandleByProfileId(uint256 profileId)
        external
        view
        returns (string memory);

    /**
     * @notice Gets the profile ID by handle.
     *
     * @param handle The profile handle.
     * @return memory the profile ID.
     */
    function getProfileIdByHandle(string calldata handle)
        external
        view
        returns (uint256);

    /**
     * @notice Sets the NFT animation url.
     *
     * @param template The new template url to set.
     */
    function setAnimationTemplate(string calldata template) external;

    /**
     * @notice Sets the NFT image.
     *
     * @param template The new template url to set.
     */
    function setImageTemplate(string calldata template) external;

    /**
     * @notice Sets the NFT metadata as IPFS hash.
     *
     * @param profileId The profile ID.
     * @param metadata The new metadata to set.
     */
    function setMetadata(uint256 profileId, string calldata metadata) external;

    /**
     * @notice Sets the NFT avatar as IPFS hash.
     *
     * @param profileId The profile ID.
     * @param avatar The new avatar to set.
     */
    function setAvatar(uint256 profileId, string calldata avatar) external;

    /**
     * @notice Gets the profile metadata.
     *
     * @param profileId The profile ID.
     * @return memory The metadata of the profile.
     */
    function getMetadata(uint256 profileId)
        external
        view
        returns (string memory);

    /**
     * @notice Gets the animation template url.
     *
     * @return memory The animation template url.
     */
    function getAnimationTemplate() external view returns (string memory);

    /**
     * @notice Gets the image template url.
     *
     * @return memory The image template url.
     */
    function getImageTemplate() external view returns (string memory);

    /**
     * @notice Gets the profile avatar.
     *
     * @param profileId The profile ID.
     * @return memory The avatar of the profile.
     */
    function getAvatar(uint256 profileId) external view returns (string memory);

    function getOperatorApproval(uint256 profileId, address operator)
        external
        view
        returns (bool);

    function setOperatorApproval(
        uint256 profileId,
        address operator,
        bool approved
    ) external;

    /**
     * @notice Sets the primary profile for the user
     *
     * @param user The address of the user
     * @param profileId The profile ID that is set to be primary
     */
    function setPrimaryProfile(address user, uint256 profileId) external;

    /**
     * @notice Gets the primary profile of the user
     *
     * @param user The wallet address of the user
     * @return profileId The primary profile of the user
     */
    function getPrimaryProfile(address user)
        external
        view
        returns (uint256 profileId);
}
