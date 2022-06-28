// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface ICyberEngineEvents {
    event Initialize(
        address indexed owner,
        address profileAddress,
        address boxAddress,
        address subscribeNFTBeacon
    );

    event SetSigner(address indexed preSigner, address indexed newSigner);

    event SetProfileAddress(
        address indexed preProfileAddr,
        address indexed newProfileAddr
    );

    event SetBoxAddress(
        address indexed preBoxAddr,
        address indexed newBoxAddress
    );

    event SetFeeByTier(
        DataTypes.Tier indexed tier,
        uint256 indexed preAmount,
        uint256 indexed newAmount
    );

    event SetBoxGiveawayEnded(bool indexed preEnded, bool indexed newEnded);

    event SetState(
        DataTypes.State indexed preState,
        DataTypes.State indexed newState
    );

    event SetAnimationTemplate(string indexed newTemplate);

    event SetImageTemplate(string indexed newTemplate);

    event SetMetadata(uint256 indexed profileId, string indexed newMetadata);

    event SetAvatar(uint256 indexed profileId, string indexed newAvatar);

    event Register(
        address indexed to,
        string indexed handle,
        string indexed avatar,
        string metadata
    );

    event Withdraw(address indexed to, uint256 indexed amount);

    // TODO: looks weird, maybe unfold the array
    event Subscribe(
        address indexed sender,
        uint256[] profileIds,
        bytes[] subDatas
    );

    event AllowSubscribeMw(
        address indexed mw,
        bool indexed preAllowed,
        bool indexed newAllowed
    );
    event SetSubscribeMw(
        uint256 indexed profileId,
        address preMw,
        address newMw
    );
    // TODO: set subscribe NFT event
}
