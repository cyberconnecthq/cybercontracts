// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

library DataTypes {
    struct ProfileStruct {
        string handle;
        string imageURI;
        address subscribeNFT;
    }

    struct EIP712Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }
}
