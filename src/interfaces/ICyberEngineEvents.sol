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

    event SetSigner(address indexed signer);

    event SetProfileAddress(address indexed profileAddress);

    event SetBoxAddress(address indexed boxAddress);

    event SetFeeByTier(DataTypes.Tier indexed tier, uint256 indexed amount);

    event SetBoxGiveawayEnded(bool ended);

    event SetState(DataTypes.State state);

    event Register(address indexed to, string indexed handle);

    event Withdraw(address indexed to, uint256 indexed amount);

    event Subscribe(
        address indexed sender,
        uint256[] profileIds,
        bytes[] subDatas
    );
}
