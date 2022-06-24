// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

library DataTypes {
    struct CreateProfileParams {
        string handle;
        string imageURI;
    }

    struct ProfileStruct {
        string handle;
        string imageURI;
    }

    struct SubscribeStruct {
        address subscribeNFT;
        address subscribeMw;
        string tokenURI;
    }

    struct EIP712Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }

    enum State {
        Operational, // green light, all running
        EssensePaused, // cannot issue new essense, TODO: maybe remove for now
        Paused // everything paused
    }

    enum Tier {
        Tier0,
        Tier1,
        Tier2,
        Tier3,
        Tier4,
        Tier5
    }
}
