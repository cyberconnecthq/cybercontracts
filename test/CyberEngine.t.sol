// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import { MockEngine } from "./utils/MockEngine.sol";
import { CyberEngine } from "../src/core/CyberEngine.sol";
import { Constants } from "../src/libraries/Constants.sol";
import { IProfileNFT } from "../src/interfaces/IProfileNFT.sol";
import { RolesAuthority } from "../src/dependencies/solmate/RolesAuthority.sol";
import { Roles } from "../src/core/Roles.sol";
import { ProfileNFT } from "../src/core/ProfileNFT.sol";
import { SubscribeNFT } from "../src/core/SubscribeNFT.sol";
import { UpgradeableBeacon } from "../src/upgradeability/UpgradeableBeacon.sol";
import { Authority } from "../src/dependencies/solmate/Auth.sol";
import { DataTypes } from "../src/libraries/DataTypes.sol";
import { ECDSA } from "../src/dependencies/openzeppelin/ECDSA.sol";
import { ICyberEngineEvents } from "../src/interfaces/ICyberEngineEvents.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { LibDeploy } from "../script/libraries/LibDeploy.sol";

contract CyberEngineTest is Test, ICyberEngineEvents {
    MockEngine internal engine;
    RolesAuthority internal rolesAuthority;
    address internal profileAddress = address(0xA);
    address internal essenceBeacon = address(0xC);
    address internal subscribeBeacon;

    address constant alice = address(0xA11CE);
    address constant bob = address(0xB0B);
    string constant handle = "handle";
    string constant handle2 = "handle2";
    string constant avatar = "avatar";
    string constant metadata = "metadata";

    function setUp() public {
        MockEngine engineImpl = new MockEngine();
        uint256 nonce = vm.getNonce(address(this));
        address engineAddr = LibDeploy._calcContractAddress(
            address(this),
            nonce + 4
        );
        rolesAuthority = new Roles(address(this), engineAddr);
        // Need beacon proxy to work, must set up fake beacon with fake impl contract
        bytes memory code = address(new ProfileNFT(engineAddr)).code;
        vm.etch(profileAddress, code);
        vm.label(engineAddr, "eng proxy");
        address impl = address(new SubscribeNFT(engineAddr, profileAddress));
        subscribeBeacon = address(new UpgradeableBeacon(impl, address(engine)));

        bytes memory data = abi.encodeWithSelector(
            CyberEngine.initialize.selector,
            address(0),
            profileAddress,
            subscribeBeacon,
            essenceBeacon,
            rolesAuthority
        );
        ERC1967Proxy engineProxy = new ERC1967Proxy(address(engineImpl), data);
        assertEq(address(engineProxy), engineAddr);
        engine = MockEngine(address(engineProxy));
    }

    function testBasic() public {
        assertEq(engine.profileAddress(), profileAddress);
        assertEq(
            uint256(engine.getState()),
            uint256(DataTypes.State.Operational)
        );
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

    function testCannotSetFeeAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(alice);
        engine.setFeeByTier(DataTypes.Tier.Tier0, 1);
    }

    function testCannotSetAniTemplateAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(alice);
        engine.setAnimationTemplate("ani_template");
    }

    function testCannotSetImgTemplateAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(alice);
        engine.setImageTemplate("img_template");
    }

    function testSetSignerAsGov() public {
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.prank(alice);

        vm.expectEmit(true, true, false, true);
        emit SetSigner(address(0), alice);

        engine.setSigner(alice);
    }

    function testSetProfileAsGov() public {
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.prank(alice);

        vm.expectEmit(true, true, false, true);
        emit SetProfileAddress(profileAddress, alice);

        engine.setProfileAddress(alice);
    }

    function testSetFeeGov() public {
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.prank(alice);

        vm.expectEmit(true, true, true, true);
        emit SetFeeByTier(
            DataTypes.Tier.Tier0,
            Constants._INITIAL_FEE_TIER0,
            1
        );

        engine.setFeeByTier(DataTypes.Tier.Tier0, 1);
        assertEq(engine.feeMapping(DataTypes.Tier.Tier0), 1);
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
        bytes32 digest = engine.hashTypedDataV4(
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
        engine.verifySignature(
            digest,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
    }

    function testCannotVerifyAsNonSigner() public {
        // change block timestamp to make deadline valid
        vm.warp(50);
        uint256 deadline = 100;
        bytes32 digest = engine.hashTypedDataV4(
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
        bytes32 digest = engine.hashTypedDataV4(
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

        vm.expectRevert("Deadline expired");
        engine.verifySignature(
            digest,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
    }

    function testInitialFees() public {
        assertEq(
            engine.feeMapping(DataTypes.Tier.Tier0),
            Constants._INITIAL_FEE_TIER0
        );
        assertEq(
            engine.feeMapping(DataTypes.Tier.Tier1),
            Constants._INITIAL_FEE_TIER1
        );
        assertEq(
            engine.feeMapping(DataTypes.Tier.Tier2),
            Constants._INITIAL_FEE_TIER2
        );
        assertEq(
            engine.feeMapping(DataTypes.Tier.Tier3),
            Constants._INITIAL_FEE_TIER3
        );
        assertEq(
            engine.feeMapping(DataTypes.Tier.Tier4),
            Constants._INITIAL_FEE_TIER4
        );
        assertEq(
            engine.feeMapping(DataTypes.Tier.Tier5),
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
        vm.expectEmit(true, true, false, true);
        emit Withdraw(alice, 1);

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
        bytes32 digest = engine.hashTypedDataV4(
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

        vm.mockCall(
            profileAddress,
            abi.encodeWithSelector(
                IProfileNFT.createProfile.selector,
                DataTypes.CreateProfileParams(bob, handle, "", "")
            ),
            abi.encode(1, true)
        );
        assertEq(engine.nonces(bob), 0);

        vm.expectEmit(true, true, false, true);
        emit Register(bob, 1, handle, avatar, metadata);

        vm.mockCall(
            profileAddress,
            abi.encodeWithSelector(
                IProfileNFT.setPrimaryProfile.selector,
                bob,
                1
            ),
            abi.encode(0)
        );

        vm.expectEmit(true, true, false, true);
        emit SetPrimaryProfile(bob, 1);

        assertEq(
            engine.register{ value: Constants._INITIAL_FEE_TIER2 }(
                DataTypes.CreateProfileParams(bob, handle, avatar, metadata),
                DataTypes.EIP712Signature(v, r, s, deadline)
            ),
            1
        );
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
        bytes32 digest = engine.hashTypedDataV4(
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

        // charlie signed the handle to bob, but register with a different address(alice).
        vm.expectRevert("Invalid signature");
        engine.register{ value: Constants._INITIAL_FEE_TIER2 }(
            DataTypes.CreateProfileParams(alice, handle, avatar, metadata),
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
        bytes32 digest = engine.hashTypedDataV4(
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
        vm.mockCall(
            profileAddress,
            abi.encodeWithSelector(
                IProfileNFT.createProfile.selector,
                DataTypes.CreateProfileParams(bob, handle, "", "")
            ),
            abi.encode(1)
        );

        engine.register{ value: Constants._INITIAL_FEE_TIER2 }(
            DataTypes.CreateProfileParams(bob, handle, avatar, metadata),
            DataTypes.EIP712Signature(v, r, s, deadline)
        );

        vm.expectRevert("Invalid signature");
        engine.register{ value: Constants._INITIAL_FEE_TIER2 }(
            DataTypes.CreateProfileParams(bob, handle, avatar, metadata),
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
    }

    function testSetState() public {
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.prank(alice);

        vm.expectEmit(true, true, false, true);
        emit SetState(DataTypes.State.Operational, DataTypes.State.Paused);

        engine.setState(DataTypes.State.Paused);
        assertEq(uint256(engine.getState()), uint256(DataTypes.State.Paused));
    }

    function testCannotSetStateWithoutAuth() public {
        vm.expectRevert("UNAUTHORIZED");
        engine.setState(DataTypes.State.Paused);
        assertEq(
            uint256(engine.getState()),
            uint256(DataTypes.State.Operational)
        );
    }

    function testCannotSubscribeWhenStateIsPaused() public {
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.prank(alice);
        engine.setState(DataTypes.State.Paused);
        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;
        bytes[] memory datas = new bytes[](1);
        vm.expectRevert("Contract is paused");
        engine.subscribe(ids, datas);
    }

    function testCannotAllowSubscribeMwAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        engine.allowSubscribeMw(address(0), true);
    }

    function testCannotAllowEssenceMwAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        engine.allowEssenceMw(address(0), true);
    }

    function testAllowSubscribeMwAsGov() public {
        address mw = address(0xCA11);
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit AllowSubscribeMw(mw, false, true);
        engine.allowSubscribeMw(mw, true);

        assertEq(engine.isSubscribeMwAllowed(mw), true);
    }

    function testAllowEssenceMwAsGov() public {
        address mw = address(0xCA11);
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit AllowEssenceMw(mw, false, true);
        engine.allowEssenceMw(mw, true);

        assertEq(engine.isEssenceMwAllowed(mw), true);
    }

    function testSetAniTemplateGov() public {
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.mockCall(
            profileAddress,
            abi.encodeWithSelector(
                IProfileNFT.setAnimationTemplate.selector,
                "new_ani_template"
            ),
            abi.encode(0)
        );

        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit SetAnimationTemplate("new_ani_template");

        engine.setAnimationTemplate("new_ani_template");
    }

    function testSetImgTemplateGov() public {
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.mockCall(
            profileAddress,
            abi.encodeWithSelector(
                IProfileNFT.setAnimationTemplate.selector,
                "new_img_template"
            ),
            abi.encode(0)
        );

        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit SetImageTemplate("new_img_template");

        engine.setImageTemplate("new_img_template");
    }

    // we can't pause from an unauthorized account
    function testCannotPauseProfileAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(alice);
        engine.pauseProfile(true);
    }

    // Profile can be paused
    // need to use mockcall
    function testPauseProfile() public {
        // contract only care about themselves, this is to set when an address
        // calls ProfileNFT, the pause(function inside) should return a value
        // the selector part is grammar
        // then we give alice an auth position
        // then we call pause
        vm.mockCall(
            profileAddress,
            abi.encodeWithSelector(ProfileNFT.pause.selector, true),
            abi.encode(0)
        );
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.prank(alice);
        engine.pauseProfile(true);
    }

    // TODO: etch is not working well with mockCall
    // function testRegisterTwiceWillNotChangePrimaryProfile() public {
    //     // register first time
    //     address charlie = vm.addr(1);
    //     rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
    //     vm.prank(alice);
    //     engine.setSigner(charlie);

    //     // change block timestamp to make deadline valid
    //     vm.warp(50);
    //     uint256 deadline = 100;
    //     bytes32 digest = engine.hashTypedDataV4(
    //         keccak256(
    //             abi.encode(
    //                 Constants._REGISTER_TYPEHASH,
    //                 bob,
    //                 keccak256(bytes(handle)),
    //                 keccak256(bytes(avatar)),
    //                 keccak256(bytes(metadata)),
    //                 0,
    //                 deadline
    //             )
    //         )
    //     );
    //     (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);

    //     vm.mockCall(
    //         profileAddress,
    //         abi.encodeWithSelector(
    //             IProfileNFT.createProfile.selector,
    //             DataTypes.CreateProfileParams(bob, handle, "", "")
    //         ),
    //         // return false here to indicate that the address has primary profile set already
    //         abi.encode(2, false)
    //     );
    //     vm.mockCall(
    //         profileAddress,
    //         abi.encodeWithSelector(
    //             IProfileNFT.setPrimaryProfile.selector,
    //             bob,
    //             1
    //         ),
    //         abi.encode(0)
    //     );
    //     assertEq(engine.nonces(bob), 0);

    //     vm.expectEmit(true, true, false, true);
    //     emit Register(bob, 1, handle, avatar, metadata);

    //     vm.expectEmit(true, true, false, true);
    //     emit SetPrimaryProfile(bob, 1);

    //     assertEq(
    //         engine.register{ value: Constants._INITIAL_FEE_TIER2 }(
    //             DataTypes.CreateProfileParams(bob, handle, avatar, metadata),
    //             DataTypes.EIP712Signature(v, r, s, deadline)
    //         ),
    //         1
    //     );
    //     assertEq(engine.nonces(bob), 1);
    // }
}
