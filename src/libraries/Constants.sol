pragma solidity 0.8.14;

library Constants {
    uint8 internal constant MINTER_ROLE = 0;
    uint8 internal constant ENGINE_GOV_ROLE = 1;
    // deconstruct the types in the struct
    bytes4 internal constant CREATE_PROFILE_ID =
        bytes4(keccak256(bytes("createProfile(address,(address,string,string))")));
    bytes4 internal constant SET_SIGNER =
        bytes4(keccak256(bytes("setSigner(address)")));
    bytes4 internal constant SET_PROFILE_ADDR =
        bytes4(keccak256(bytes("setProfileAddress(address)")));
    bytes4 internal constant SET_BOX_ADDR =
        bytes4(keccak256(bytes("setBoxAddress(address)")));

    // Parameters
    uint8 internal constant MAX_HANDLE_LENGTH = 27;
}
