// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

library DataTypes {
    struct CreateProfileParams {
        string handle;
        string imageURI;
        address subscribeMw;
    }

    struct ProfileStruct {
        string handle;
        string imageURI;
        address subscribeNFT;
        address subscribeMw;
    }

    struct EIP712Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }
}
