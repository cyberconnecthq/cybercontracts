// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

library DataTypes {
    struct EIP712Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }

    struct CreateProfileParams {
        address to;
        string handle;
        string avatar;
        string metadata;
    }

    struct CreateNamespaceParams {
        string name;
        string symbol;
        address owner;
        ComputedAddresses addrs;
    }

    struct SubscribeData {
        address sender;
        uint256[] profileIds;
        bytes[] preDatas;
        bytes[] postDatas;
        address subBeacon;
    }

    struct CollectData {
        address collector;
        uint256 profileId;
        uint256 essenceId;
        bytes preData;
        bytes postData;
        address essBeacon;
    }

    struct RegisterEssenceData {
        uint256 profileId;
        string name;
        string symbol;
        string essenceTokenURI;
        address essenceMw;
        bytes prepareData;
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

    struct NamespaceStruct {
        address owner;
        address profileMw;
        string name;
    }

    struct ConstructTokenURIParams {
        uint256 tokenId;
        string handle;
        uint256 subscribers;
    }

    struct ComputedAddresses {
        address authority;
        address profileProxy;
        // address subscribeImpl;
        // address essenceImpl;
        address profileFactory;
        address subscribeFactory;
        address essenceFactory;
    }

    struct ProfileDeployParameters {
        address engine;
        address subBeacon;
        address essenceBeacon;
    }

    struct SubscribeDeployParameters {
        address profileProxy;
    }

    struct EssenceDeployParameters {
        address profileProxy;
    }
}
