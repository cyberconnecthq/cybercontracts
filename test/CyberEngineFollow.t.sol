// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "forge-std/Test.sol";
import { MockEngine } from "./utils/MockEngine.sol";
import { TestAuthority } from "./utils/TestAuthority.sol";
import { RolesAuthority } from "../src/base/RolesAuthority.sol";
import { Constants } from "../src/libraries/Constants.sol";
import { IBoxNFT } from "../src/interfaces/IBoxNFT.sol";
import { IProfileNFT } from "../src/interfaces/IProfileNFT.sol";
import { DataTypes } from "../src/libraries/DataTypes.sol";

contract CyberEngineFollowTest is Test {
    MockEngine internal engine;
    RolesAuthority internal authority;
    address internal profileAddress = address(0xA);
    address internal boxAddress = address(0xB);
    address internal gov = address(0xA11CE);
    uint256 internal bobPk = 1;
    address internal bob = vm.addr(bobPk);

    function setUp() public {
        authority = new TestAuthority(address(this));
        engine = new MockEngine();
        engine.initialize(address(0), profileAddress, boxAddress, authority);
        authority.setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            address(engine),
            Constants._SET_SIGNER,
            true
        );
        authority.setUserRole(gov, Constants._ENGINE_GOV_ROLE, true);
        vm.prank(gov);
        engine.setSigner(bob);

        // register "bob"
        string memory handle = "bob";
        uint256 deadline = 100;
        bytes32 digest = engine.hashTypedDataV4(
            keccak256(abi.encode(Constants._REGISTER, bob, handle, 0, deadline))
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);

        vm.mockCall(
            boxAddress,
            abi.encodeWithSelector(IBoxNFT.mint.selector, address(bob)),
            abi.encode(1)
        );

        vm.mockCall(
            profileAddress,
            abi.encodeWithSelector(
                IProfileNFT.createProfile.selector,
                address(bob),
                DataTypes.ProfileStruct(handle, "", address(0))
            ),
            abi.encode(1)
        );

        assertEq(engine.nonces(bob), 0);

        engine.register{ value: Constants._INITIAL_FEE_TIER2 }(
            bob,
            handle,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );

        assertEq(engine.nonces(bob), 1);
    }

    function testCannotFollowEmptyList() public {
        vm.expectRevert("No profile ids provided");
        uint256[] memory empty;
        engine.follow(empty);
    }

    function testFollow() public {}
}
