// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";
import { IProfileNFTEvents } from "./IProfileNFTEvents.sol";

interface IProfileNFT is IProfileNFTEvents {
    /**
     * @notice Creates a profile and mints it to the recipient address.
     *
     * @param data contains all params.
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
    function createProfile(bytes calldata data)
        external
        payable
        returns (uint256);

    /**
     * @notice Gets the profile handle by ID.
     *
     * @param profileId The profile ID.
     * @return string the profile handle.
     */
    function getHandleByProfileId(uint256 profileId)
        external
        view
        returns (string memory);

    /**
     * @notice Gets the profile ID by handle.
     *
     * @param handle The profile handle.
     * @return uint256 the profile ID.
     */
    function getProfileIdByHandle(string calldata handle)
        external
        view
        returns (uint256);

    /**
     * @notice Sets the Profile NFT Descriptor.
     *
     * @param descriptor The new descriptor address to set.
     */
    function setProfileNFTDescriptor(address descriptor) external;

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
     * @return string The metadata of the profile.
     */
    function getMetadata(uint256 profileId)
        external
        view
        returns (string memory);

    /**
     * @notice Gets the profile NFT descriptor.
     *
     * @return address The descriptor address.
     */
    function getProfileNFTDescriptor() external view returns (address);

    /**
     * @notice Sets the profile NFT animation template.
     *
     * @param template The new template.
     */
    function setAnimationTemplate(string calldata template) external;

    /**
     * @notice Gets the profile avatar.
     *
     * @param profileId The profile ID.
     * @return string The avatar of the profile.
     */
    function getAvatar(uint256 profileId) external view returns (string memory);

    /**
     * @notice Gets the operator approval status.
     *
     * @param profileId The profile ID.
     * @param operator The operator address.
     * @return bool The approval status.
     */
    function getOperatorApproval(uint256 profileId, address operator)
        external
        view
        returns (bool);

    /**
     * @notice Sets the operator approval.
     *
     * @param profileId The profile ID.
     * @param operator The operator address.
     * @param approved The approval status.
     */
    function setOperatorApproval(
        uint256 profileId,
        address operator,
        bool approved
    ) external;

    /**
     * @notice Sets the primary profile for the user.
     *
     * @param profileId The profile ID that is set to be primary.
     */
    function setPrimaryProfile(uint256 profileId) external;

    /**
     * @notice Gets the primary profile of the user.
     *
     * @param user The wallet address of the user.
     * @return profileId The primary profile of the user.
     */
    function getPrimaryProfile(address user)
        external
        view
        returns (uint256 profileId);

    /**
     * @notice Gets the Subscribe NFT token URI.
     *
     * @param profileId The profile ID.
     * @return string The Subscribe NFT token URI.
     */
    function getSubscribeNFTTokenURI(uint256 profileId)
        external
        view
        returns (string memory);

    /**
     * @notice Gets the Subscribe NFT address.
     *
     * @param profileId The profile ID.
     * @return address The Subscribe NFT address.
     */
    function getSubscribeNFT(uint256 profileId) external view returns (address);

    function getEssenceNFTTokenURI(uint256 profileId, uint256 essenceId)
        external
        view
        returns (string memory);

    function getEssenceNFT(uint256 profileId, uint256 essenceId)
        external
        view
        returns (address);
}
