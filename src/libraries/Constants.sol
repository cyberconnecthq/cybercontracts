// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

library Constants {
    // Access Control for ProfileNFT & BoxNFT
    uint8 internal constant _NFT_MINTER_ROLE = 0;
    bytes4 internal constant _PROFILE_CREATE_PROFILE_ID =
        bytes4(
            keccak256(bytes("createProfile(address,(string,string,address))"))
        );
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
    bytes4 internal constant _SET_FEE_BY_TIER =
        bytes4(keccak256(bytes("setFeeByTier(uint8,uint256)")));
    bytes4 internal constant _SET_BOX_OPENED =
        bytes4(keccak256(bytes("setBoxOpened(bool)")));
    bytes4 internal constant _REGISTER =
        bytes4(keccak256(bytes("register(address,string,uint256,uint256)")));
    bytes4 internal constant _WITHDRAW =
        bytes4(keccak256(bytes("withdraw(address,uint256)")));
    bytes4 internal constant _AUTHORIZE_UPGRADE =
        bytes4(keccak256(bytes("upgradeTo(address)")));

    // Parameters
    uint8 internal constant _MAX_HANDLE_LENGTH = 27;

    // Initial States
    uint256 internal constant _INITIAL_FEE_TIER0 = 0.5 ether;
    uint256 internal constant _INITIAL_FEE_TIER1 = 0.1 ether;
    uint256 internal constant _INITIAL_FEE_TIER2 = 0.06 ether;
    uint256 internal constant _INITIAL_FEE_TIER3 = 0.03 ether;
    uint256 internal constant _INITIAL_FEE_TIER4 = 0.01 ether;
    uint256 internal constant _INITIAL_FEE_TIER5 = 0.006 ether;

    // Access Control for UpgradeableBeacon
    bytes4 internal constant _BEACON_UPGRADE_TO =
        bytes4(keccak256(bytes("upgradeTo(address)")));

    // Subscribe NFT
    string internal constant _SUBSCRIBE_NFT_NAME_SUFFIX = "_subscriber";
    string internal constant _SUBSCRIBE_NFT_SYMBOL_SUFFIX = "_SUB";
}
