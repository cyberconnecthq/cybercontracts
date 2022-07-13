// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ProfileNFT } from "../../src/core/ProfileNFT.sol";
import { RolesAuthority } from "../../src/dependencies/solmate/RolesAuthority.sol";
import { Constants } from "../../src/libraries/Constants.sol";
import { DataTypes } from "../../src/libraries/DataTypes.sol";
import { IProfileNFT } from "../../src/interfaces/IProfileNFT.sol";
import { TestLib712 } from "./TestLib712.sol";
import { LibDeploy } from "../../script/libraries/LibDeploy.sol";
import { PermissionedFeeCreationMw } from "../../src/middlewares/profile/PermissionedFeeCreationMw.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";

// Only for testing, not for deploying script
// TODO: move to test folder
library TestLibFixture {
    // Need to be called after auth
    string private constant avatar = "avatar";
    string private constant metadata = "metadata";

    function registerBobProfile(
        Vm vm,
        ProfileNFT profile,
        PermissionedFeeCreationMw mw,
        string memory handle,
        address mintToEOA,
        uint256 signerPk
    ) internal returns (uint256 profileId) {
        uint256 deadline = block.timestamp + 60 * 60;
        uint256 nonce = mw.getNonce(address(profile), mintToEOA);

        bytes32 digest = TestLib712.hashTypedDataV4(
            address(mw),
            keccak256(
                abi.encode(
                    Constants._CREATE_PROFILE_TYPEHASH,
                    mintToEOA,
                    keccak256(bytes(handle)),
                    keccak256(bytes(avatar)),
                    keccak256(bytes(metadata)),
                    nonce,
                    deadline
                )
            ),
            "PermissionedFeeCreationMw",
            "1"
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, digest);
        profileId = profile.createProfile{
            value: LibDeploy._INITIAL_FEE_TIER2
        }(
            DataTypes.CreateProfileParams(mintToEOA, handle, avatar, metadata),
            abi.encode(v, r, s, deadline)
        );
        // require(profileId == 1);
        require(mw.getNonce(address(profile), mintToEOA) == nonce + 1);
    }
}
