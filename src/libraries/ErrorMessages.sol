// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

library ErrorMessages {
    string internal constant _ZERO_OPERATOR_ADDRESS = "Operator: zero address";
    string internal constant _ZERO_SIGNER_ADDRESS = "Signer: zero address";
    string internal constant _ZERO_PROFILE_ADDRESS =
        "ProfileAddress: zero address";
    string internal constant _ZERO_BOX_ADDRESS = "BoxAddress: zero address";
    string internal constant _ZERO_WITHDRAW_ADDRESS = "Withdraw: zero address";
    string internal constant _ZERO_ENGINE_ADDRESS =
        "EngineAddress: zero address";
    string internal constant _ZERO_PROFILE_NFT_ADDRESS =
        "ProfileNft: zero address";
    string internal constant _PROFILE_HANDLE_TAKEN =
        "CreateProfile: handle taken";
    string internal constant _PROFILE_HANDLE_INVALID_LENGTH =
        "ValidateHandle: invalid length";
    string internal constant _PROFILE_HANDLE_INVALID_CHAR =
        "ValidateHandle: invalid char";
    string internal constant _PROFILE_ONLY_ENGINE =
        "CreateProfile: only engine";
    string internal constant _WITHDRAW_INSUFF_BAL =
        "Withdraw: insufficient balance";
    string internal constant _VERIFY_DEADLINE_EXP =
        "VerifySig: deadline expired";
    string internal constant _VERIFY_INVALID_SIG = "VerifySig: invalid sig";
    string internal constant _REGISTER_INVALID_LENGTH =
        "RegisterHandle: invalid length";
    string internal constant _REGISTER_INSUFF_FEE =
        "RegisterFee: insufficient fee";
    string internal constant _ENGINE_MINT =
        "SubscribeNftMint: only engine can mint";
    string internal constant _UNALLOWED_TRANSFER =
        "SubscribeNftTransfer: unallowed";
    string internal constant _INITIALIZED = "Initializer: already initialized";
    string internal constant _CONTRACT_NOT_INITIALIZING =
        "Initializable: contract is not initializing";
    string internal constant _CONTRACT_INITIALIZING =
        "Initializable: contract is initializing";
    string internal constant _TOKEN_NOT_MINTED = "ERC721: not minted";
    string internal constant _NO_PROFILE_IDS =
        "ProfileIds: no profile ids provided";
    string internal constant _CONTRACT_PAUSED = "Contract: contract is paused";
    string internal constant _ESSENSE_PAUSED = "Essense: essense is paused";
    string internal constant _OWNER_ONLY = "Owner: only owner";
    string internal constant _OWNER_OPERATOR_ONLY =
        "Owner: only owner or operator";
    string internal constant _LENGTH_MISMATCH = "Length: lenght missmatch";
}
