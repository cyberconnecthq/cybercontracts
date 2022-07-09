// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";
import { MockProfile } from "./utils/MockProfile.sol";
import { RolesAuthority } from "../src/dependencies/solmate/RolesAuthority.sol";
import { Constants } from "../src/libraries/Constants.sol";
import { IProfileNFT } from "../src/interfaces/IProfileNFT.sol";
import { ISubscribeNFT } from "../src/interfaces/ISubscribeNFT.sol";
import { DataTypes } from "../src/libraries/DataTypes.sol";
import { UpgradeableBeacon } from "../src/upgradeability/UpgradeableBeacon.sol";
import { Auth, Authority } from "../src/dependencies/solmate/Auth.sol";
import { SubscribeNFT } from "../src/core/SubscribeNFT.sol";
import { ProfileNFT } from "../src/core/ProfileNFT.sol";
import { ERC721 } from "../src/dependencies/solmate/ERC721.sol";
import { IProfileNFTEvents } from "../src/interfaces/IProfileNFTEvents.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { LibDeploy } from "../script/libraries/LibDeploy.sol";
import { Roles } from "../src/core/Roles.sol";

// For tests that requires a profile to start with.
contract ProfileNFTInteractTest is Test, IProfileNFTEvents {
    MockProfile internal engine;
    RolesAuthority internal authority;
    address internal subscribeBeacon;
    address internal gov = address(0xCCC);
    uint256 internal bobPk = 10000;
    address internal bob = vm.addr(bobPk);
    uint256 internal profileId;
    address internal alice = address(0xA11CE);
    address mw = address(0xCA11);

    function setUp() public {
        address fakeImpl = address(new SubscribeNFT(address(0xdead)));
        subscribeBeacon = address(
            new UpgradeableBeacon(fakeImpl, address(engine))
        );
        MockProfile engineImpl = new MockProfile(subscribeBeacon, address(0));
        uint256 nonce = vm.getNonce(address(this));
        address engineAddr = LibDeploy._calcContractAddress(
            address(this),
            nonce + 3
        );
        authority = new Roles(address(this), engineAddr);

        // Need beacon proxy to work, must set up fake beacon with fake impl contract

        address impl = address(new SubscribeNFT(engineAddr));
        subscribeBeacon = address(new UpgradeableBeacon(impl, address(engine)));
        address essenceBeacon = address(0);

        bytes memory data = abi.encodeWithSelector(
            ProfileNFT.initialize.selector,
            address(0),
            "Name",
            "Symbol",
            address(0x233),
            authority
        );
        ERC1967Proxy engineProxy = new ERC1967Proxy(address(engineImpl), data);
        assertEq(address(engineProxy), engineAddr);
        engine = MockProfile(address(engineProxy));
        vm.label(address(engine), "EngineProxy");
        vm.label(address(this), "Tester");
        vm.label(bob, "Bob");

        authority.setUserRole(address(gov), Constants._PROFILE_GOV_ROLE, true);
        vm.prank(gov);
        engine.setSigner(bob);

        // register "bob"
        string memory handle = "bob";
        string memory avatar = "avatar";
        string memory metadata = "metadata";

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
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(bobPk, digest);

        assertEq(engine.nonces(bob), 0);
        profileId = engine.createProfile{ value: Constants._INITIAL_FEE_TIER2 }(
            DataTypes.CreateProfileParams(bob, handle, avatar, metadata),
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
        assertEq(profileId, 1);

        assertEq(engine.nonces(bob), 1);

        vm.prank(gov);
        engine.allowSubscribeMw(mw, true);

        assertEq(engine.isSubscribeMwAllowed(mw), true);
    }

    function testCannotSubscribeEmptyList() public {
        vm.expectRevert("No profile ids provided");
        uint256[] memory empty;
        bytes[] memory data;
        engine.subscribe(empty, data);
    }

    function testSubscribe() public {
        address subscribeProxy = address(0xC0DE);
        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;
        bytes[] memory datas = new bytes[](1);

        engine.setSubscribeNFTAddress(1, subscribeProxy);
        uint256 result = 100;
        vm.mockCall(
            subscribeProxy,
            abi.encodeWithSelector(ISubscribeNFT.mint.selector, address(this)),
            abi.encode(result)
        );
        uint256[] memory expected = new uint256[](1);
        expected[0] = result;

        vm.expectEmit(true, false, false, true);
        emit Subscribe(address(this), ids, datas);

        uint256[] memory called = engine.subscribe(ids, datas);
        assertEq(called.length, expected.length);
        assertEq(called[0], expected[0]);
    }

    function testSubscribeDeployProxy() public {
        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;
        bytes[] memory datas = new bytes[](1);

        uint256 result = 100;

        // Assuming the newly deployed subscribe proxy is always at the same address;
        uint256 nonce = vm.getNonce(address(engine));
        address subscribeProxy = LibDeploy._calcContractAddress(
            address(engine),
            nonce
        );
        address proxy = address(subscribeProxy);
        vm.mockCall(
            proxy,
            abi.encodeWithSelector(ISubscribeNFT.mint.selector, address(this)),
            abi.encode(result)
        );

        uint256[] memory expected = new uint256[](1);
        expected[0] = result;
        uint256[] memory called = engine.subscribe(ids, datas);

        assertEq(called.length, expected.length);
        assertEq(called[0], expected[0]);

        assertEq(engine.getSubscribeNFT(1), proxy);
    }

    // TODO: add test for subscribe to multiple profiles

    // TODO: use integration test instead of mock
    function testCannotSetOperatorIfNotOwner() public {
        vm.expectRevert("ONLY_PROFILE_OWNER");
        engine.setOperatorApproval(profileId, address(0), true);
    }

    function testSetOperatorAsOwner() public {
        vm.prank(bob);

        vm.expectEmit(true, true, true, true);
        emit SetOperatorApproval(profileId, gov, false, true);
        engine.setOperatorApproval(profileId, gov, true);
    }

    function testSetMetadataAsOwner() public {
        vm.prank(bob);

        vm.expectEmit(true, false, false, true);
        emit SetMetadata(profileId, "ipfs");
        engine.setMetadata(profileId, "ipfs");
    }

    function testSetMetadataWithSig() public {
        // set all subsequent calls' from bob (but signer/owner is charlie).
        vm.startPrank(bob);

        string memory metadata = "ipfs";
        vm.warp(50);
        uint256 deadline = 100;
        assertEq(engine.nonces(bob), 1);

        bytes32 digest = engine.hashTypedDataV4(
            keccak256(
                abi.encode(
                    Constants._SET_METADATA_TYPEHASH,
                    profileId,
                    keccak256(bytes(metadata)),
                    1,
                    deadline
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(bobPk, digest);

        vm.expectEmit(true, false, false, true);
        emit SetMetadata(profileId, metadata);
        engine.setMetadataWithSig(
            profileId,
            metadata,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
    }

    function testSubscribeWithSig() public {
        //let Charlie subscribe Bob's profile while the sender is Alice
        vm.startPrank(alice);

        uint256 charliePk = 100;
        address charlie = vm.addr(charliePk);

        uint256[] memory profileIds = new uint256[](1);
        bytes[] memory subDatas = new bytes[](1);
        bytes32[] memory hashes = new bytes32[](1);
        profileIds[0] = 1;
        subDatas[0] = bytes("simple subdata");
        hashes[0] = keccak256(subDatas[0]);

        vm.warp(50);
        uint256 deadline = 100;

        bytes32 digest = engine.hashTypedDataV4(
            keccak256(
                abi.encode(
                    Constants._SUBSCRIBE_TYPEHASH,
                    keccak256(abi.encodePacked(profileIds)),
                    keccak256(abi.encodePacked(hashes)),
                    0,
                    deadline
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(charliePk, digest);

        // Assuming the newly deployed subscribe proxy is always at the same address;
        uint256 nonce = vm.getNonce(address(engine));
        address subscribeProxy = LibDeploy._calcContractAddress(
            address(engine),
            nonce
        );
        address proxy = address(subscribeProxy);

        vm.mockCall(
            proxy,
            abi.encodeWithSelector(ISubscribeNFT.mint.selector, charlie),
            abi.encode(1)
        );

        vm.expectEmit(true, false, false, true);
        emit Subscribe(charlie, profileIds, subDatas);

        engine.subscribeWithSig(
            profileIds,
            subDatas,
            charlie,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
    }

    function testSetOperatorApprovalWithSig() public {
        vm.startPrank(alice);

        bytes[] memory subDatas = new bytes[](1);
        subDatas[0] = bytes("simple subdata");
        bool approved = true;

        vm.warp(50);
        uint256 deadline = 100;

        assertEq(engine.nonces(bob), 1);
        bytes32 digest = engine.hashTypedDataV4(
            keccak256(
                abi.encode(
                    Constants._SET_OPERATOR_APPROVAL_TYPEHASH,
                    profileId,
                    gov,
                    approved,
                    1,
                    deadline
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(bobPk, digest);

        vm.expectEmit(true, false, false, true);
        emit SetOperatorApproval(profileId, gov, false, approved);

        engine.setOperatorApprovalWithSig(
            profileId,
            gov,
            approved,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
    }

    function testCannotSetMetadataWithSigInvalidSig() public {
        // set all subsequent calls' from bob
        vm.startPrank(bob);

        string memory metadata = "ipfs";
        vm.warp(50);
        uint256 deadline = 100;
        bytes32 digest = engine.hashTypedDataV4(
            keccak256(
                abi.encode(
                    Constants._SET_METADATA_TYPEHASH,
                    profileId,
                    keccak256(bytes(metadata)),
                    0,
                    deadline
                )
            )
        );

        // signer is bob, however owner is charlie
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(bobPk, digest);

        vm.expectRevert("INVALID_SIGNATURE");
        engine.setMetadataWithSig(
            profileId,
            metadata,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
    }

    function testCannotSetMetadataAsNonOwnerAndOperator() public {
        vm.expectRevert("ONLY_PROFILE_OWNER_OR_OPERATOR");
        engine.setMetadata(profileId, "ipfs");
    }

    function testSetMetadataAsOperator() public {
        string memory metadata = "ipfs";
        vm.prank(bob);
        engine.setOperatorApproval(profileId, alice, true);
        vm.prank(alice);
        engine.setMetadata(profileId, metadata);
    }

    function testSetAvatarAsOwner() public {
        vm.prank(bob);
        engine.setAvatar(profileId, "avatar");
    }

    function testCannotSetAvatarAsNonOwnerAndOperator() public {
        vm.expectRevert("ONLY_PROFILE_OWNER_OR_OPERATOR");
        engine.setAvatar(profileId, "avatar");
    }

    function testSetAvatarAsOperator() public {
        string memory avatar = "avatar";
        vm.prank(bob);
        engine.setOperatorApproval(profileId, alice, true);
        vm.prank(alice);
        engine.setAvatar(profileId, avatar);
    }

    function testCannotSetSubscribeMwIfNotOwner() public {
        vm.expectRevert("ONLY_PROFILE_OWNER");
        engine.setSubscribeMw(profileId, mw);
    }

    function testCannotSetSubscribeMwIfNotAllowed() public {
        vm.expectRevert("SUB_MW_NOT_ALLOWED");
        address notMw = address(0xDEEAAAD);
        vm.prank(bob);
        engine.setSubscribeMw(profileId, notMw);
        assertEq(engine.getSubscribeMw(profileId), address(0));
    }

    function testSetSubscribeMw() public {
        vm.prank(bob);
        engine.setSubscribeMw(profileId, mw);
        assertEq(engine.getSubscribeMw(profileId), mw);
    }

    function testSetPrimary() public {
        vm.prank(bob);

        vm.expectEmit(true, true, false, true);
        emit SetPrimaryProfile(bob, profileId);
        engine.setPrimaryProfile(profileId);
    }

    function testCannotSetPrimaryAsNonOwner() public {
        vm.expectRevert("ONLY_PROFILE_OWNER");
        engine.setPrimaryProfile(profileId);
    }
}
