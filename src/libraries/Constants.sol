pragma solidity 0.8.14;

library Constants {
    // Access Control for ProfileNFT
    uint8 internal constant PROFILE_MINTER_ROLE = 0;
    bytes4 internal constant CREATE_PROFILE_ID =
        bytes4(keccak256(bytes("createProfile(address,(string,string))")));

    // Parameters
    uint8 internal constant MAX_HANDLE_LENGTH = 27;
}