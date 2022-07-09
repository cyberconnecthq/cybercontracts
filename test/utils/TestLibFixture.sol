// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ProfileNFT } from "../../src/core/ProfileNFT.sol";
import { RolesAuthority } from "../../src/dependencies/solmate/RolesAuthority.sol";
import { Constants } from "../../src/libraries/Constants.sol";
import { DataTypes } from "../../src/libraries/DataTypes.sol";
import { IProfileNFT } from "../../src/interfaces/IProfileNFT.sol";
import { TestLib712 } from "./TestLib712.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";

// Only for testing, not for deploying script
// TODO: move to test folder
library TestLibFixture {
    address constant _GOV = address(0xC11); // TODO: dont hardcode this

    address private constant VM_ADDRESS =
        address(bytes20(uint160(uint256(keccak256("hevm cheat code")))));
    Vm public constant vm = Vm(VM_ADDRESS);

    function auth(RolesAuthority authority) internal {
        authority.setUserRole(_GOV, Constants._PROFILE_GOV_ROLE, true);
    }

    function registerBobProfile(ProfileNFT engine)
        internal
        returns (uint256 profileId)
    {
        return registerBobProfile(engine, 0, "bob");
    }

    // Need to be called after auth
    function registerBobProfile(
        ProfileNFT engine,
        uint256 nonce,
        string memory handle
    ) internal returns (uint256 profileId) {
        uint256 bobPk = 1;
        address bob = vm.addr(bobPk);
        // set signer
        vm.prank(_GOV);
        engine.setSigner(bob);

        uint256 deadline = 100;
        string memory avatar = "avatar";
        string memory metadata = "metadata";
        bytes32 digest = TestLib712.hashTypedDataV4(
            address(engine),
            keccak256(
                abi.encode(
                    Constants._REGISTER_TYPEHASH,
                    bob,
                    keccak256(bytes(handle)),
                    keccak256(bytes(avatar)),
                    keccak256(bytes(metadata)),
                    nonce,
                    deadline
                )
            ),
            "Link3 Profile",
            "1"
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);

        require(engine.nonces(bob) == nonce);
        profileId = engine.createProfile{ value: Constants._INITIAL_FEE_TIER2 }(
            DataTypes.CreateProfileParams(bob, handle, avatar, metadata),
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
        // require(profileId == 1);

        require(engine.nonces(bob) == nonce + 1);
    }
}
