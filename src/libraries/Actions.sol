// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "./DataTypes.sol";

library Actions {
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

    function createProfile(
        uint256 id,
        uint256 _totalCount,
        DataTypes.CreateProfileParams calldata params,
        mapping(uint256 => DataTypes.ProfileStruct) storage _profileById,
        mapping(bytes32 => uint256) storage _profileIdByHandleHash,
        mapping(uint256 => string) storage _metadataById,
        mapping(address => uint256) storage _addressToPrimaryProfile
    ) external {
        bytes32 handleHash = keccak256(bytes(params.handle));
        //require(!_exists(_profileIdByHandleHash[handleHash]), "HANDLE_TAKEN");

        _profileById[_totalCount].handle = params.handle;
        _profileById[_totalCount].avatar = params.avatar;

        _profileIdByHandleHash[handleHash] = _totalCount;
        _metadataById[_totalCount] = params.metadata;

        emit CreateProfile(
            params.to,
            id,
            params.handle,
            params.avatar,
            params.metadata
        );

        if (_addressToPrimaryProfile[params.to] == 0) {
            _addressToPrimaryProfile[params.to] = id;
            emit SetPrimaryProfile(params.to, id);
        }
    }
}
