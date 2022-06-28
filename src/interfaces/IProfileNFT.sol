// SPDX-License-Identifier: MIT

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
     *  and the following conditions must be met:
     *  - The caller address must be the engine address.
     * - The recipient address must be a valid Ethereum address.
     * - The handle must be a valid UTF-8 string.
     * - The handle must not be already used.
     * - The handle must not be longer than 32 bytes.
     * - The handle must not be empty.
     */
    function createProfile(DataTypes.CreateProfileParams calldata params)
        external
        returns (uint256);

    /**
     * @notice Gets the profile handle.
     *
     * @param profileId The profile ID.
     * @return memory the profile handle.
     */
    function getHandleByProfileId(uint256 profileId)
        external
        view
        returns (string memory);

    /**
     * @notice Gets the profile handle.
     *
     * @param handle The profile handle.
     * @return memory the profile ID.
     */
    function getProfileIdByHandle(string calldata handle)
        external
        view
        returns (uint256);

    /**
     * @notice Sets the NFT animation image.
     *
     * @param template The new template uri to set.
     */
    function setAnimationTemplate(string calldata template) external;

    /**
     * @notice Sets the NFT image.
     *
     * @param template The new template uri to set.
     */
    function setImageTemplate(string calldata template) external;

    /**
     * @notice Sets the NFT metadata.
     *
     * @param profileId The profile ID.
     * @param metadata The new metadata to set.
     */
    function setMetadata(uint256 profileId, string calldata metadata) external;

    /**
     * @notice Gets the animation template uri.
     *
     * @return memory the animation template uri.
     */
    function getAnimationTemplate() external view returns (string memory);

    /**
     * @notice Gets the image template uri.
     *
     * @return memory the image template uri.
     */
    function getImageTemplate() external view returns (string memory);

    /**
     * @notice Gets the profile metadata.
     *
     * @param profileId The profile ID.
     * @return memory the metadata of the profile.
     */
    function getMetadata(uint256 profileId)
        external
        view
        returns (string memory);

    function getOperatorApproval(uint256 profileId, address operator)
        external
        view
        returns (bool);

    function setOperatorApproval(
        uint256 profileId,
        address operator,
        bool approved
    ) external;
}
