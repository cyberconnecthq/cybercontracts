pragma solidity 0.8.14;

library Constants {
    uint8 internal constant MINTER_ROLE = 0;
    bytes4 internal constant CREATE_PROFILE_ID =
        bytes4(keccak256(bytes("createProfile()")));
}