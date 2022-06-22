// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import { MockEngine } from "./utils/MockEngine.sol";
import { CyberEngine } from "../src/CyberEngine.sol";
import { Constants } from "../src/libraries/Constants.sol";
import { IBoxNFT } from "../src/interfaces/IBoxNFT.sol";
import { IProfileNFT } from "../src/interfaces/IProfileNFT.sol";
import { RolesAuthority } from "../src/base/RolesAuthority.sol";
import { Authority } from "../src/base/Auth.sol";
import { DataTypes } from "../src/libraries/DataTypes.sol";
import { ECDSA } from "../src/dependencies/openzeppelin/ECDSA.sol";

contract MockBoxNFT is IBoxNFT {
    bool public mintRan;

    function mint(address _to) external returns (uint256) {
        mintRan = true;
        return 0;
    }
}

contract MockProfileNFT is IProfileNFT {
    bool public createProfileRan;

    function createProfile(address to, DataTypes.ProfileStruct calldata vars)
        external
        returns (uint256)
    {
        createProfileRan = true;
    }

    function getHandleByProfileId(uint256 profildId)
        external
        view
        returns (string memory)
    {
        return "";
    }

    function getSubscribeNFTAddressByProfileId(uint256 profileId)
        external
        view
        returns (address)
    {
        return address(0);
    }

    function setSubscribeNFTAddress(uint256 profileId, address subscribeNFT)
        external
    {}
}

contract CyberEngineTest is Test {
    MockEngine internal engine;
    RolesAuthority internal rolesAuthority;
    MockBoxNFT internal box;
    MockProfileNFT internal profile;
    address constant alice = address(0xA11CE);
    address constant bob = address(0xB0B);

    function setUp() public {
        rolesAuthority = new RolesAuthority(
            address(this),
            Authority(address(0))
        );
        box = new MockBoxNFT();
        profile = new MockProfileNFT();
        engine = new MockEngine();
        engine.initialize(
            address(0),
            address(profile),
            address(box),
            address(0xDEAD),
            rolesAuthority
        );
        rolesAuthority.setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            address(engine),
            Constants._SET_SIGNER,
            true
        );
        rolesAuthority.setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            address(engine),
            Constants._SET_PROFILE_ADDR,
            true
        );
        rolesAuthority.setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            address(engine),
            Constants._SET_BOX_ADDR,
            true
        );
        rolesAuthority.setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            address(engine),
            Constants._SET_FEE_BY_TIER,
            true
        );
        rolesAuthority.setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            address(engine),
            Constants._WITHDRAW,
            true
        );
        rolesAuthority.setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            address(engine),
            Constants._SET_BOX_OPENED,
            true
        );
    }

    function testBasic() public {
        assertEq(engine.profileAddress(), address(profile));
        assertEq(engine.boxAddress(), address(box));
        assertEq(engine.boxOpened(), false);
    }

    function testAuth() public {
        assertEq(address(engine.authority()), address(rolesAuthority));
    }

    function testCannotSetSignerAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(alice);
        engine.setSigner(alice);
    }

    function testCannotSetProfileAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(alice);
        engine.setProfileAddress(alice);
    }

    function testCannotSetBoxAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(alice);
        engine.setBoxAddress(alice);
    }

    function testCannotSetFeeAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(alice);
        engine.setFeeByTier(CyberEngine.Tier.Tier0, 1);
    }

    function testCannotSetBoxOpenedAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(alice);
        engine.setBoxOpened(true);
    }

    function testSetSignerAsGov() public {
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.prank(alice);
        engine.setSigner(alice);
    }

    function testSetProfileAsGov() public {
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.prank(alice);
        engine.setProfileAddress(alice);
    }

    function testSetBoxGov() public {
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.prank(alice);
        engine.setBoxAddress(alice);
    }

    function testSetFeeGov() public {
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.prank(alice);
        engine.setFeeByTier(CyberEngine.Tier.Tier0, 1);
        assertEq(engine.feeMapping(CyberEngine.Tier.Tier0), 1);
    }

    function testSetBoxOpenedGov() public {
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.prank(alice);
        engine.setBoxOpened(true);
    }

    function testVerify() public {
        // set charlie as signer
        address charlie = vm.addr(1);
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.prank(alice);
        engine.setSigner(charlie);

        // change block timestamp to make deadline valid
        vm.warp(50);
        uint256 deadline = 100;

        string memory handle = "bob_handle";
        bytes32 digest = engine.hashTypedDataV4(
            keccak256(abi.encode(Constants._REGISTER, bob, handle, 0, deadline))
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);
        engine.verifySignature(
            digest,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
    }

    function testCannotVerifyAsNonSigner() public {
        // change block timestamp to make deadline valid
        vm.warp(50);
        uint256 deadline = 100;

        string memory handle = "bob_handle";
        bytes32 digest = engine.hashTypedDataV4(
            keccak256(abi.encode(Constants._REGISTER, bob, handle, 0, deadline))
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);

        vm.expectRevert("Invalid signature");
        engine.verifySignature(
            digest,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
    }

    function testCannotVerifyDeadlinePassed() public {
        // change block timestamp to make deadline invalid
        vm.warp(150);
        uint256 deadline = 100;

        string memory handle = "bob_handle";
        bytes32 digest = engine.hashTypedDataV4(
            keccak256(abi.encode(Constants._REGISTER, bob, handle, 0, deadline))
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);

        vm.expectRevert("Deadline expired");
        engine.verifySignature(
            digest,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
    }

    function testInitialFees() public {
        assertEq(
            engine.feeMapping(CyberEngine.Tier.Tier0),
            Constants._INITIAL_FEE_TIER0
        );
        assertEq(
            engine.feeMapping(CyberEngine.Tier.Tier1),
            Constants._INITIAL_FEE_TIER1
        );
        assertEq(
            engine.feeMapping(CyberEngine.Tier.Tier2),
            Constants._INITIAL_FEE_TIER2
        );
        assertEq(
            engine.feeMapping(CyberEngine.Tier.Tier3),
            Constants._INITIAL_FEE_TIER3
        );
        assertEq(
            engine.feeMapping(CyberEngine.Tier.Tier4),
            Constants._INITIAL_FEE_TIER4
        );
        assertEq(
            engine.feeMapping(CyberEngine.Tier.Tier5),
            Constants._INITIAL_FEE_TIER5
        );
    }

    function testRequireEnoughFeeTier0() public view {
        engine.requireEnoughFee("A", Constants._INITIAL_FEE_TIER0);
    }

    function testCannotMeetFeeRequirement0() public {
        vm.expectRevert("Insufficient fee");
        engine.requireEnoughFee("A", Constants._INITIAL_FEE_TIER0 - 1);
    }

    function testRequireEnoughFeeTier1() public view {
        engine.requireEnoughFee("AB", Constants._INITIAL_FEE_TIER1);
    }

    function testCannotMeetFeeRequirement1() public {
        vm.expectRevert("Insufficient fee");
        engine.requireEnoughFee("AB", Constants._INITIAL_FEE_TIER1 - 1);
    }

    function testRequireEnoughFeeTier2() public view {
        engine.requireEnoughFee("ABC", Constants._INITIAL_FEE_TIER2);
    }

    function testCannotMeetFeeRequirement2() public {
        vm.expectRevert("Insufficient fee");
        engine.requireEnoughFee("ABC", Constants._INITIAL_FEE_TIER2 - 1);
    }

    function testRequireEnoughFeeTier3() public view {
        engine.requireEnoughFee("ABCD", Constants._INITIAL_FEE_TIER3);
    }

    function testCannotMeetFeeRequirement3() public {
        vm.expectRevert("Insufficient fee");
        engine.requireEnoughFee("ABCD", Constants._INITIAL_FEE_TIER3 - 1);
    }

    function testRequireEnoughFeeTier4() public view {
        engine.requireEnoughFee("ABCDE", Constants._INITIAL_FEE_TIER4);
    }

    function testCannotMeetFeeRequirement4() public {
        vm.expectRevert("Insufficient fee");
        engine.requireEnoughFee("ABCDE", Constants._INITIAL_FEE_TIER4 - 1);
    }

    function testRequireEnoughFeeTier5() public view {
        engine.requireEnoughFee("ABCDEFG", Constants._INITIAL_FEE_TIER5);
    }

    function testCannotMeetFeeRequirement5() public {
        vm.expectRevert("Insufficient fee");
        engine.requireEnoughFee("ABCDEFG", Constants._INITIAL_FEE_TIER5 - 1);
    }

    function testWithdraw() public {
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.deal(address(engine), 2);
        assertEq(address(engine).balance, 2);
        assertEq(alice.balance, 0);

        vm.prank(alice);
        engine.withdraw(alice, 1);
        assertEq(address(engine).balance, 1);
        assertEq(alice.balance, 1);
    }

    function testCannotWithdrawInsufficientBal() public {
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.prank(alice);

        vm.expectRevert("Insufficient balance");
        engine.withdraw(alice, 1);
    }

    function testCannotWithdrawAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        engine.withdraw(alice, 1);
    }

    function testRegister() public {
        address charlie = vm.addr(1);
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.prank(alice);
        engine.setSigner(charlie);

        // change block timestamp to make deadline valid
        vm.warp(50);
        uint256 deadline = 100;

        string memory handle = "bob";
        bytes32 digest = engine.hashTypedDataV4(
            keccak256(abi.encode(Constants._REGISTER, bob, handle, 0, deadline))
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);

        assertEq(box.mintRan(), false);
        assertEq(profile.createProfileRan(), false);
        assertEq(engine.nonces(bob), 0);

        assertEq(
            engine.register{ value: Constants._INITIAL_FEE_TIER2 }(
                bob,
                handle,
                DataTypes.EIP712Signature(v, r, s, deadline)
            ),
            1
        );

        assertEq(box.mintRan(), true);
        assertEq(profile.createProfileRan(), true);
        assertEq(engine.nonces(bob), 1);
    }

    function testCannotRegisterInvalidSig() public {
        // set charlie as signer
        address charlie = vm.addr(1);
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.prank(alice);
        engine.setSigner(charlie);

        // change block timestamp to make deadline valid
        vm.warp(50);
        uint256 deadline = 100;

        string memory handle = "bob_handle";
        bytes32 digest = engine.hashTypedDataV4(
            keccak256(abi.encode(Constants._REGISTER, bob, handle, 0, deadline))
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);

        // charlie signed the handle to bob, but register with a different address(alice).
        vm.expectRevert("Invalid signature");
        engine.register{ value: Constants._INITIAL_FEE_TIER2 }(
            alice,
            handle,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
    }

    function testCannotRegisterReplay() public {
        // set charlie as signer
        address charlie = vm.addr(1);
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.prank(alice);
        engine.setSigner(charlie);

        // change block timestamp to make deadline valid
        vm.warp(50);
        uint256 deadline = 100;

        string memory handle = "bob_handle";
        bytes32 digest = engine.hashTypedDataV4(
            keccak256(abi.encode(Constants._REGISTER, bob, handle, 0, deadline))
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);
        engine.register{ value: Constants._INITIAL_FEE_TIER2 }(
            bob,
            handle,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );

        vm.expectRevert("Invalid signature");
        engine.register{ value: Constants._INITIAL_FEE_TIER2 }(
            bob,
            handle,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
    }

    function testRegisterAfterBoxOpened() public {
        address charlie = vm.addr(1);
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.prank(alice);
        engine.setBoxOpened(true);

        vm.prank(alice);
        engine.setSigner(charlie);

        // change block timestamp to make deadline valid
        vm.warp(50);
        uint256 deadline = 100;

        string memory handle = "bob";
        bytes32 digest = engine.hashTypedDataV4(
            keccak256(abi.encode(Constants._REGISTER, bob, handle, 0, deadline))
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);

        assertEq(box.mintRan(), false);
        assertEq(profile.createProfileRan(), false);
        assertEq(engine.nonces(bob), 0);

        engine.register{ value: Constants._INITIAL_FEE_TIER2 }(
            bob,
            handle,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );

        assertEq(box.mintRan(), false);
        assertEq(profile.createProfileRan(), true);
        assertEq(engine.nonces(bob), 1);
    }
}
