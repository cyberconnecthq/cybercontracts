// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

library Constants {
    // Access Control for CyebreEngine
    uint8 internal constant _ENGINE_GOV_ROLE = 1;
    bytes4 internal constant _AUTHORIZE_UPGRADE =
        bytes4(keccak256(bytes("_authorizeUpgrade(address)")));

    // EIP712 TypeHash
    bytes32 internal constant _REGISTER_TYPEHASH =
        keccak256(
            "register(address to,string handle,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant _SUBSCRIBE_TYPEHASH =
        keccak256(
            "subscribeWithSig(uint256[] profileIds,bytes[] subDatas,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant _SET_METADATA_TYPEHASH =
        keccak256(
            "setMetadataWithSig(uint256 profileId,string metadata,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant _SET_OPERATOR_APPROVAL_TYPEHASH =
        keccak256(
            "setOperatorApprovalWithSign(uint256 profileId,address operator,bool approved,uint256 nonce,uint256 deadline)"
        );

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
