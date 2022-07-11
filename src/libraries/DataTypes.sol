// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

library DataTypes {
    struct CreateProfileParams {
        address to;
        string handle;
        string avatar;
        string metadata;
    }

    struct ProfileStruct {
        string handle;
        string avatar;
        uint256 essenceCount;
    }

    struct SubscribeStruct {
        address subscribeNFT;
        address subscribeMw;
        string tokenURI;
    }

    struct EssenceStruct {
        address essenceNFT;
        address essenceMw;
        string name;
        string symbol;
        string tokenURI;
    }

    struct EIP712Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }

    struct ConstructTokenURIParams {
        uint256 tokenId;
        string handle;
        uint256 subscribers;
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
