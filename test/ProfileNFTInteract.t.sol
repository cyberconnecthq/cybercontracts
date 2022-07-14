// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { ERC721 } from "../src/dependencies/solmate/ERC721.sol";

import { IProfileNFT } from "../src/interfaces/IProfileNFT.sol";
import { ICyberEngine } from "../src/interfaces/ICyberEngine.sol";
import { ISubscribeNFT } from "../src/interfaces/ISubscribeNFT.sol";
import { IEssenceNFT } from "../src/interfaces/IEssenceNFT.sol";
import { ISubscribeMiddleware } from "../src/interfaces/ISubscribeMiddleware.sol";
import { IEssenceMiddleware } from "../src/interfaces/IEssenceMiddleware.sol";
import { IProfileNFTEvents } from "../src/interfaces/IProfileNFTEvents.sol";

import { Constants } from "../src/libraries/Constants.sol";
import { DataTypes } from "../src/libraries/DataTypes.sol";

import { MockProfile } from "./utils/MockProfile.sol";
import { UpgradeableBeacon } from "../src/upgradeability/UpgradeableBeacon.sol";
import { SubscribeNFT } from "../src/core/SubscribeNFT.sol";
import { EssenceNFT } from "../src/core/EssenceNFT.sol";
import { ProfileNFT } from "../src/core/ProfileNFT.sol";
import { LibDeploy } from "../script/libraries/LibDeploy.sol";
import { TestLib712 } from "./utils/TestLib712.sol";
import { TestDeployer } from "./utils/TestDeployer.sol";

// For tests that requires a profile to start with.
contract ProfileNFTInteractTest is Test, IProfileNFTEvents, TestDeployer {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed id
    );

    MockProfile internal profile;
    address internal subscribeBeacon;
    address internal essenceBeacon;
    address internal gov = address(0xCCC);
    address internal engine = address(0x888);
    uint256 internal bobPk = 10000;
    address internal bob = vm.addr(bobPk);
    uint256 internal profileId;
    address internal alice = address(0xA11CE);
    address subscribeMw = address(0xCA11);
    address essenceMw = address(0xCA112);
    bytes internal profileData = "0x1";

    function setUp() public {
        vm.etch(subscribeMw, address(this).code);
        vm.etch(essenceMw, address(this).code);
        vm.etch(engine, address(this).code);

        // Need beacon proxy to work, must set up fake beacon with fake impl contract
        address fakeImpl = deploySubscribe(_salt, address(0xdead));
        subscribeBeacon = address(
            new UpgradeableBeacon(fakeImpl, address(profile))
        );
        address fakeEssenceImpl = deployEssence(_salt, address(0xdead));
        essenceBeacon = address(
            new UpgradeableBeacon(fakeEssenceImpl, address(profile))
        );
        address profileImpl = testDeployMockProfile(
            engine,
            essenceBeacon,
            subscribeBeacon
        );
        uint256 nonce = vm.getNonce(address(this));
        bytes memory data = abi.encodeWithSelector(
            ProfileNFT.initialize.selector,
            gov,
            "Name",
            "Symbol"
        );
        ERC1967Proxy profileProxy = new ERC1967Proxy(profileImpl, data);
        profile = MockProfile(address(profileProxy));

        assertEq(profile.nonces(bob), 0);
        string memory handle = "bob";
        string memory avatar = "avatar";
        string memory metadata = "metadata";

        profileId = profile.createProfile(
            DataTypes.CreateProfileParams(bob, handle, avatar, metadata)
        );
        assertEq(profileId, 1);
        assertEq(profile.nonces(bob), 0);
    }

    function testCannotSubscribeEmptyList() public {
        vm.expectRevert("NO_PROFILE_IDS");
        uint256[] memory empty;
        bytes[] memory data;
        profile.subscribe(DataTypes.SubscribeParams(empty), data, data);
    }

    function testCannotSubscribeNonExistsingProfile() public {
        vm.expectRevert("NOT_MINTED");
        uint256[] memory ids = new uint256[](1);
        ids[0] = 2;
        bytes[] memory data = new bytes[](1);
        profile.subscribe(DataTypes.SubscribeParams(ids), data, data);
    }

    function testSubscribe() public {
        address subscribeProxy = address(0xC0DE);
        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;
        bytes[] memory datas = new bytes[](1);

        profile.setSubscribeNFTAddress(1, subscribeProxy);
        uint256 result = 100;
        vm.mockCall(
            subscribeProxy,
            abi.encodeWithSelector(ISubscribeNFT.mint.selector, address(this)),
            abi.encode(result)
        );
        uint256[] memory expected = new uint256[](1);
        expected[0] = result;

        vm.expectEmit(true, false, false, true);
        emit Subscribe(address(this), ids, datas, datas);

        uint256[] memory called = profile.subscribe(
            DataTypes.SubscribeParams(ids),
            datas,
            datas
        );
        assertEq(called.length, expected.length);
        assertEq(called[0], expected[0]);
    }

    function testSubscribeDeployProxy() public {
        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;
        bytes[] memory datas = new bytes[](1);

        uint256 result = 100;

        // Assuming the newly deployed subscribe proxy is always at the same address;
        uint256 nonce = vm.getNonce(address(profile));
        address subscribeProxy = LibDeploy._calcContractAddress(
            address(profile),
            nonce
        );
        vm.mockCall(
            subscribeProxy,
            abi.encodeWithSelector(ISubscribeNFT.mint.selector, address(this)),
            abi.encode(result)
        );

        uint256[] memory expected = new uint256[](1);
        expected[0] = result;
        uint256[] memory called = profile.subscribe(
            DataTypes.SubscribeParams(ids),
            datas,
            datas
        );

        assertEq(called.length, expected.length);
        assertEq(called[0], expected[0]);

        assertEq(profile.getSubscribeNFT(1), subscribeProxy);
    }

    // TODO: add test for subscribe to multiple profiles

    function testCannotSetOperatorIfNotOwner() public {
        vm.expectRevert("ONLY_PROFILE_OWNER");
        profile.setOperatorApproval(profileId, address(0), true);
    }

    function testSetOperatorAsOwner() public {
        vm.prank(bob);

        vm.expectEmit(true, true, true, true);
        emit SetOperatorApproval(profileId, gov, false, true);
        profile.setOperatorApproval(profileId, gov, true);
    }

    function testSetMetadataAsOwner() public {
        vm.prank(bob);

        vm.expectEmit(true, false, false, true);
        emit SetMetadata(profileId, "ipfs");
        profile.setMetadata(profileId, "ipfs");
    }

    function testSetMetadataWithSig() public {
        // set all subsequent calls' from bob (but signer/owner is charlie).
        vm.startPrank(bob);

        string memory metadata = "ipfs";
        vm.warp(50);
        uint256 deadline = 100;

        bytes32 digest = TestLib712.hashTypedDataV4(
            address(profile),
            keccak256(
                abi.encode(
                    Constants._SET_METADATA_TYPEHASH,
                    profileId,
                    keccak256(bytes(metadata)),
                    profile.nonces(bob),
                    deadline
                )
            ),
            profile.name(),
            "1"
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(bobPk, digest);

        vm.expectEmit(true, false, false, true);
        emit SetMetadata(profileId, metadata);
        profile.setMetadataWithSig(
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

        bytes32 digest = TestLib712.hashTypedDataV4(
            address(profile),
            keccak256(
                abi.encode(
                    Constants._SUBSCRIBE_TYPEHASH,
                    keccak256(abi.encodePacked(profileIds)),
                    keccak256(abi.encodePacked(hashes)),
                    keccak256(abi.encodePacked(hashes)),
                    profile.nonces(bob),
                    deadline
                )
            ),
            profile.name(),
            "1"
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(charliePk, digest);

        // Assuming the newly deployed subscribe proxy is always at the same address;
        uint256 nonce = vm.getNonce(address(profile));
        address subscribeProxy = LibDeploy._calcContractAddress(
            address(profile),
            nonce
        );

        vm.mockCall(
            subscribeProxy,
            abi.encodeWithSelector(ISubscribeNFT.mint.selector, charlie),
            abi.encode(1)
        );

        vm.expectEmit(true, false, false, true);
        emit Subscribe(charlie, profileIds, subDatas, subDatas);

        profile.subscribeWithSig(
            DataTypes.SubscribeParams(profileIds),
            subDatas,
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

        bytes32 digest = TestLib712.hashTypedDataV4(
            address(profile),
            keccak256(
                abi.encode(
                    Constants._SET_OPERATOR_APPROVAL_TYPEHASH,
                    profileId,
                    gov,
                    approved,
                    profile.nonces(bob),
                    deadline
                )
            ),
            profile.name(),
            "1"
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(bobPk, digest);

        vm.expectEmit(true, false, false, true);
        emit SetOperatorApproval(profileId, gov, false, approved);

        profile.setOperatorApprovalWithSig(
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
        bytes32 digest = TestLib712.hashTypedDataV4(
            address(profile),
            keccak256(
                abi.encode(
                    Constants._SET_METADATA_TYPEHASH,
                    profileId,
                    keccak256(bytes(metadata)),
                    profile.nonces(bob) + 1,
                    deadline
                )
            ),
            profile.name(),
            "1"
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(bobPk, digest);

        // nonce should be 0
        vm.expectRevert("INVALID_SIGNATURE");
        profile.setMetadataWithSig(
            profileId,
            metadata,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
    }

    function testCannotSetMetadataAsNonOwnerAndOperator() public {
        vm.expectRevert("ONLY_PROFILE_OWNER_OR_OPERATOR");
        profile.setMetadata(profileId, "ipfs");
    }

    function testSetMetadataAsOperator() public {
        string memory metadata = "ipfs";
        vm.prank(bob);
        profile.setOperatorApproval(profileId, alice, true);
        vm.prank(alice);
        profile.setMetadata(profileId, metadata);
    }

    function testSetAvatarAsOwner() public {
        vm.prank(bob);
        profile.setAvatar(profileId, "avatar");
    }

    function testCannotSetAvatarAsNonOwnerAndOperator() public {
        vm.expectRevert("ONLY_PROFILE_OWNER_OR_OPERATOR");
        profile.setAvatar(profileId, "avatar");
    }

    function testSetAvatarAsOperator() public {
        string memory avatar = "avatar";
        vm.prank(bob);
        profile.setOperatorApproval(profileId, alice, true);
        vm.prank(alice);
        profile.setAvatar(profileId, avatar);
    }

    function testCannotSetSubscribeMwIfNotOwner() public {
        vm.expectRevert("ONLY_PROFILE_OWNER");
        profile.setSubscribeMw(profileId, subscribeMw, new bytes(0));
    }

    function testCannotSetSubscribeMwIfNotAllowed() public {
        vm.expectRevert("SUB_MW_NOT_ALLOWED");
        address notMw = address(0xDEEAAAD);

        vm.mockCall(
            engine,
            abi.encodeWithSelector(
                ICyberEngine.isSubscribeMwAllowed.selector,
                notMw
            ),
            abi.encode(false)
        );

        vm.prank(bob);
        profile.setSubscribeMw(profileId, notMw, new bytes(0));
        assertEq(profile.getSubscribeMw(profileId), address(0));
    }

    function testSetSubscribeMw() public {
        vm.mockCall(
            engine,
            abi.encodeWithSelector(
                ICyberEngine.isSubscribeMwAllowed.selector,
                subscribeMw
            ),
            abi.encode(true)
        );
        bytes memory data = new bytes(0);
        bytes memory returnData = new bytes(111);
        vm.mockCall(
            subscribeMw,
            abi.encodeWithSelector(
                ISubscribeMiddleware.prepare.selector,
                profileId,
                data
            ),
            abi.encode(returnData)
        );
        vm.expectEmit(true, false, false, true);
        emit SetSubscribeMw(profileId, subscribeMw, returnData);
        vm.prank(bob);
        profile.setSubscribeMw(profileId, subscribeMw, data);

        assertEq(profile.getSubscribeMw(profileId), subscribeMw);
    }

    function testSetSubscribeMwZeroAddress() public {
        address zeroAddress = address(0);

        bytes memory data = new bytes(0);
        vm.expectEmit(true, false, false, true);
        emit SetSubscribeMw(profileId, zeroAddress, new bytes(0));
        vm.prank(bob);
        profile.setSubscribeMw(profileId, zeroAddress, data);

        assertEq(profile.getSubscribeMw(profileId), zeroAddress);
    }

    function testSetPrimary() public {
        vm.prank(bob);

        vm.expectEmit(true, true, false, true);
        emit SetPrimaryProfile(bob, profileId);
        profile.setPrimaryProfile(profileId);
    }

    function testCannotSetPrimaryAsNonOwner() public {
        vm.expectRevert("ONLY_PROFILE_OWNER");
        profile.setPrimaryProfile(profileId);
    }

    function testCannotRegisterEssenceIfProfileNotMinted() public {
        vm.expectRevert("NOT_MINTED");
        uint256 nonExistentProfileId = 8888;
        profile.registerEssence(
            DataTypes.RegisterEssenceParams(
                nonExistentProfileId,
                "name",
                "symbol",
                "uri",
                essenceMw
            ),
            new bytes(0)
        );
    }

    function testCannotRegisterEssenceIfNotOwnerOrOperator() public {
        address charlie = address(0xDEEAAAD);
        vm.expectRevert("ONLY_PROFILE_OWNER_OR_OPERATOR");
        vm.prank(charlie);
        profile.registerEssence(
            DataTypes.RegisterEssenceParams(
                profileId,
                "name",
                "symbol",
                "uri",
                essenceMw
            ),
            new bytes(0)
        );
    }

    function testCannotRegisterEssenceWithEssenceMwNotAllowed() public {
        address notMw = address(0xDEEAAAD);
        vm.mockCall(
            engine,
            abi.encodeWithSelector(
                ICyberEngine.isEssenceMwAllowed.selector,
                notMw
            ),
            abi.encode(false)
        );

        vm.expectRevert("ESSENCE_MW_NOT_ALLOWED");
        vm.prank(bob);
        profile.registerEssence(
            DataTypes.RegisterEssenceParams(
                profileId,
                "name",
                "symbol",
                "uri",
                notMw
            ),
            new bytes(0)
        );
    }

    function testRegisterEssenceAsProfileOwner() public {
        vm.mockCall(
            engine,
            abi.encodeWithSelector(
                ICyberEngine.isEssenceMwAllowed.selector,
                essenceMw
            ),
            abi.encode(true)
        );

        vm.prank(bob);
        uint256 expectedEssenceId = 1;
        bytes memory returnData = new bytes(111);
        vm.mockCall(
            essenceMw,
            abi.encodeWithSelector(
                IEssenceMiddleware.prepare.selector,
                profileId,
                expectedEssenceId,
                new bytes(0)
            ),
            abi.encode(returnData)
        );
        vm.expectEmit(true, true, false, false);
        string memory name = "name";
        string memory symbol = "symbol";
        string memory uri = "uri";

        emit RegisterEssence(
            profileId,
            expectedEssenceId,
            name,
            symbol,
            uri,
            essenceMw,
            returnData
        );
        uint256 essenceId = profile.registerEssence(
            DataTypes.RegisterEssenceParams(
                profileId,
                name,
                symbol,
                uri,
                essenceMw
            ),
            new bytes(0)
        );
        assertEq(essenceId, expectedEssenceId);
    }

    function testCannotCollectEssenceIfNotRegistered() public {
        vm.expectRevert("ESSENCE_NOT_REGISTERED");
        profile.collect(
            DataTypes.CollectParams(profileId, 1),
            new bytes(0),
            new bytes(0)
        );
    }

    function testCollectEssence() public {
        vm.prank(bob);
        uint256 expectedEssenceId = 1;

        // register without middleware
        uint256 essenceId = profile.registerEssence(
            DataTypes.RegisterEssenceParams(
                profileId,
                "name",
                "symbol",
                "uri",
                address(0)
            ),
            new bytes(0)
        );
        assertEq(essenceId, expectedEssenceId);

        // privilege access
        address essenceProxy = address(0x01111);
        profile.setEssenceNFTAddress(profileId, essenceId, essenceProxy);

        uint256 tokenId = 1890;

        address minter = address(0x1890);
        vm.mockCall(
            essenceProxy,
            abi.encodeWithSelector(IEssenceNFT.mint.selector, minter),
            abi.encode(tokenId)
        );

        vm.expectEmit(true, false, false, true);
        emit CollectEssence(minter, profileId, new bytes(0), new bytes(0));

        vm.prank(minter);
        profile.collect(
            DataTypes.CollectParams(profileId, essenceId),
            new bytes(0),
            new bytes(0)
        );
    }

    function testCollectEssenceDeployEssenceNFT() public {
        vm.prank(bob);
        uint256 expectedEssenceId = 1;

        // register without middleware
        uint256 essenceId = profile.registerEssence(
            DataTypes.RegisterEssenceParams(
                profileId,
                "name",
                "symbol",
                "uri",
                address(0)
            ),
            new bytes(0)
        );
        assertEq(essenceId, expectedEssenceId);

        uint256 tokenId = 1890;

        address minter = address(0x1890);
        uint256 nonce = vm.getNonce(address(profile));
        address essenceProxy = LibDeploy._calcContractAddress(
            address(profile),
            nonce
        );
        vm.mockCall(
            essenceProxy,
            abi.encodeWithSelector(IEssenceNFT.mint.selector, minter),
            abi.encode(tokenId)
        );

        vm.expectEmit(true, false, false, true);
        emit CollectEssence(minter, profileId, new bytes(0), new bytes(0));

        vm.expectEmit(true, true, false, true);
        emit DeployEssenceNFT(profileId, essenceId, essenceProxy);

        vm.prank(minter);
        profile.collect(
            DataTypes.CollectParams(profileId, essenceId),
            new bytes(0),
            new bytes(0)
        );
    }

    function testCollectEssenceWithSig() public {
        vm.prank(bob);
        uint256 expectedEssenceId = 1;

        // register without middleware
        uint256 essenceId = profile.registerEssence(
            DataTypes.RegisterEssenceParams(
                profileId,
                "name",
                "symbol",
                "uri",
                address(0)
            ),
            new bytes(0)
        );
        assertEq(essenceId, expectedEssenceId);

        uint256 tokenId = 1890;

        address minter = bob;
        uint256 nonce = vm.getNonce(address(profile));
        address essenceProxy = LibDeploy._calcContractAddress(
            address(profile),
            nonce
        );
        vm.mockCall(
            essenceProxy,
            abi.encodeWithSelector(IEssenceNFT.mint.selector, minter),
            abi.encode(tokenId)
        );

        bytes memory preData = new bytes(0);
        bytes memory postData = new bytes(0);

        vm.expectEmit(true, false, false, true);
        emit CollectEssence(minter, profileId, preData, postData);

        vm.expectEmit(true, true, false, true);
        emit DeployEssenceNFT(profileId, essenceId, essenceProxy);

        // sign
        vm.warp(50);
        uint256 deadline = 100;
        bytes32 digest = TestLib712.hashTypedDataV4(
            address(profile),
            keccak256(
                abi.encode(
                    Constants._COLLECT_TYPEHASH,
                    profileId,
                    essenceId,
                    keccak256(preData),
                    keccak256(postData),
                    profile.nonces(bob),
                    deadline
                )
            ),
            profile.name(),
            "1"
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(bobPk, digest);

        profile.collectWithSig(
            DataTypes.CollectParams(profileId, essenceId),
            preData,
            postData,
            bob,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
    }

    function testPermit() public {
        assertEq(profile.getApproved(profileId), address(0));

        vm.warp(50);
        uint256 deadline = 100;
        bytes32 data = keccak256(
            abi.encode(
                Constants._PERMIT_TYPEHASH,
                alice,
                profileId,
                profile.nonces(bob),
                deadline
            )
        );
        bytes32 digest = TestLib712.hashTypedDataV4(
            address(profile),
            data,
            profile.name(),
            "1"
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(bobPk, digest);
        vm.expectEmit(true, true, true, true);
        emit Approval(bob, alice, profileId);
        profile.permit(
            alice,
            profileId,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
        assertEq(profile.getApproved(profileId), alice);
    }
}
