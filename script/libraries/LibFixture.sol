// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { CyberEngine } from "../../src/core/CyberEngine.sol";
import { ECDSA } from "../../src/dependencies/openzeppelin/ECDSA.sol";
import { RolesAuthority } from "../../src/dependencies/solmate/RolesAuthority.sol";
import { Constants } from "../../src/libraries/Constants.sol";
import { DataTypes } from "../../src/libraries/DataTypes.sol";
import { IBoxNFT } from "../../src/interfaces/IBoxNFT.sol";
import { IProfileNFT } from "../../src/interfaces/IProfileNFT.sol";
import "forge-std/Vm.sol";

// Only for testing, not for deploying script
// TODO: move to test folder
library LibFixture {
    address constant _GOV = address(0xC11); // TODO: dont hardcode this
    bytes32 private constant _TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    address private constant VM_ADDRESS =
        address(bytes20(uint160(uint256(keccak256("hevm cheat code")))));
    Vm public constant vm = Vm(VM_ADDRESS);

    // Util function
    function _hashTypedDataV4(address engineAddr, bytes32 structHash)
        private
        view
        returns (bytes32)
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                _TYPE_HASH,
                keccak256(bytes("CyberEngine")),
                keccak256(bytes("1")),
                block.chainid,
                engineAddr
            )
        );
        return ECDSA.toTypedDataHash(domainSeparator, structHash);
    }

    function auth(RolesAuthority authority) internal {
        authority.setUserRole(_GOV, Constants._ENGINE_GOV_ROLE, true);
    }

    // Need to be called after auth
    function registerBobProfile(CyberEngine engine)
        internal
        returns (uint256 profileId)
    {
        uint256 bobPk = 1;
        address bob = vm.addr(bobPk);
        string memory handle = "bob";
        // set signer
        vm.prank(_GOV);
        engine.setSigner(bob);

        uint256 deadline = 100;
        string memory avatar = "avatar";
        string memory metadata = "metadata";
        bytes32 digest = _hashTypedDataV4(
            address(engine),
            keccak256(
                abi.encode(
                    Constants._REGISTER_TYPEHASH,
                    bob,
                    keccak256(bytes(handle)),
                    keccak256(bytes(avatar)),
                    keccak256(bytes(metadata)),
                    0,
                    deadline
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);

        require(engine.nonces(bob) == 0);
        profileId = engine.register{ value: Constants._INITIAL_FEE_TIER2 }(
            DataTypes.CreateProfileParams(bob, handle, avatar, metadata),
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
        // require(profileId == 1);

        require(engine.nonces(bob) == 1);
    }
}
