// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

library Constants {
    // Access Control for ProfileNFT & BoxNFT
    uint8 internal constant _NFT_MINTER_ROLE = 0;
    bytes4 internal constant _PROFILE_CREATE_PROFILE_ID =
        bytes4(keccak256(bytes("createProfile(address,(string,string))")));
    bytes4 internal constant _BOX_MINT =
        bytes4(keccak256(bytes("mint(address)")));

    // Access Control for CyebreEngine
    uint8 internal constant _ENGINE_GOV_ROLE = 1;
    bytes4 internal constant _SET_SIGNER =
        bytes4(keccak256(bytes("setSigner(address)")));
    bytes4 internal constant _SET_PROFILE_ADDR =
        bytes4(keccak256(bytes("setProfileAddress(address)")));
    bytes4 internal constant _SET_BOX_ADDR =
        bytes4(keccak256(bytes("setBoxAddress(address)")));
    bytes4 internal constant _REGISTER =
        bytes4(keccak256(bytes("register(address,string,uint256)")));

    // Parameters
    uint8 internal constant _MAX_HANDLE_LENGTH = 27;
}
