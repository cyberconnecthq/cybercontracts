// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";
import { MockEngine } from "./utils/MockEngine.sol";
import { RolesAuthority } from "../src/dependencies/solmate/RolesAuthority.sol";
import { Constants } from "../src/libraries/Constants.sol";
import { IBoxNFT } from "../src/interfaces/IBoxNFT.sol";
import { IProfileNFT } from "../src/interfaces/IProfileNFT.sol";
import { ISubscribeNFT } from "../src/interfaces/ISubscribeNFT.sol";
import { DataTypes } from "../src/libraries/DataTypes.sol";
import { UpgradeableBeacon } from "../src/upgradeability/UpgradeableBeacon.sol";
import { Auth, Authority } from "../src/dependencies/solmate/Auth.sol";
import { SubscribeNFT } from "../src/core/SubscribeNFT.sol";
import { CyberEngine } from "../src/core/CyberEngine.sol";
import { ProfileNFT } from "../src/core/ProfileNFT.sol";
import { ERC721 } from "../src/dependencies/solmate/ERC721.sol";
import { ICyberEngineEvents } from "../src/interfaces/ICyberEngineEvents.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { LibDeploy } from "../script/libraries/LibDeploy.sol";

// For tests that requires a profile to start with.
contract CyberEngineInteractTest is Test, ICyberEngineEvents {
    MockEngine internal engine;
    RolesAuthority internal authority;
    address internal profileAddress = address(0xA);
    address internal boxAddress = address(0xB);
    address internal subscribeBeacon;
    address internal gov = address(0xCCC);
    uint256 internal bobPk = 10000;
    address internal bob = vm.addr(bobPk);
    uint256 internal profileId;
    address internal alice = address(0xA11CE);
    address mw = address(0xCA11);

    function setUp() public {
        authority = new RolesAuthority(address(this), Authority(address(0)));
        MockEngine engineImpl = new MockEngine();
        uint256 nonce = vm.getNonce(address(this));
        address engineAddr = LibDeploy._calcContractAddress(
            address(this),
            nonce + 3
        );
        // Need beacon proxy to work, must set up fake beacon with fake impl contract
        bytes memory code = address(new ProfileNFT(engineAddr)).code;
        vm.etch(profileAddress, code);

        address impl = address(new SubscribeNFT(engineAddr, profileAddress));
        subscribeBeacon = address(new UpgradeableBeacon(impl, address(engine)));
        address essenceBeacon = address(0);

        bytes memory data = abi.encodeWithSelector(
            CyberEngine.initialize.selector,
            address(0),
            profileAddress,
            boxAddress,
            subscribeBeacon,
            essenceBeacon,
            authority
        );
        ERC1967Proxy engineProxy = new ERC1967Proxy(address(engineImpl), data);
        assertEq(address(engineProxy), engineAddr);
        engine = MockEngine(address(engineProxy));
        vm.label(address(engine), "EngineProxy");
        vm.label(address(this), "Tester");
        vm.label(bob, "Bob");

        authority.setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            address(engine),
            CyberEngine.setSigner.selector,
            true
        );
        authority.setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            address(engine),
            CyberEngine.allowSubscribeMw.selector,
            true
        );
        authority.setUserRole(gov, Constants._ENGINE_GOV_ROLE, true);
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

        vm.mockCall(
            boxAddress,
            abi.encodeWithSelector(IBoxNFT.mint.selector, address(bob)),
            abi.encode(1)
        );

        vm.mockCall(
            profileAddress,
            abi.encodeWithSelector(
                IProfileNFT.createProfile.selector,
                DataTypes.CreateProfileParams(bob, handle, "", "")
            ),
            abi.encode(1)
        );

        assertEq(engine.nonces(bob), 0);
        profileId = engine.register{ value: Constants._INITIAL_FEE_TIER2 }(
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
        address proxy = address(0x93474D608089d9Fa2347A19A0a85EdC8ce562FeA);
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
        vm.mockCall(
            profileAddress,
            abi.encodeWithSelector(ERC721.ownerOf.selector, profileId),
            abi.encode(address(0xDEAD))
        );
        vm.expectRevert("Only profile owner");
        engine.setOperatorApproval(profileId, address(0), true);
    }

    function testSetOperatorAsOwner() public {
        vm.mockCall(
            profileAddress,
            abi.encodeWithSelector(ERC721.ownerOf.selector, profileId),
            abi.encode(alice)
        );
        vm.prank(alice);

        vm.expectEmit(true, true, true, true);
        emit SetOperatorApproval(profileId, gov, true);
        engine.setOperatorApproval(profileId, gov, true);
    }

    function testSetMetadataAsOwner() public {
        vm.prank(bob);
        vm.mockCall(
            profileAddress,
            abi.encodeWithSelector(ERC721.ownerOf.selector, profileId),
            abi.encode(bob)
        );

        vm.expectEmit(true, false, false, true);
        emit SetMetadata(profileId, "ipfs");
        engine.setMetadata(profileId, "ipfs");
    }

    function testSetMetadataWithSig() public {
        // set all subsequent calls' from bob (but signer/owner is charlie).
        vm.startPrank(bob);

        uint256 charliePk = 100;
        address charlie = vm.addr(charliePk);
        vm.mockCall(
            profileAddress,
            abi.encodeWithSelector(ERC721.ownerOf.selector, profileId),
            abi.encode(charlie)
        );
        assertEq(ERC721(profileAddress).ownerOf(profileId), charlie);

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
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(charliePk, digest);

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

        vm.mockCall(
            profileAddress,
            abi.encodeWithSelector(ERC721.ownerOf.selector, 1),
            abi.encode(charlie)
        );

        assertEq(ERC721(profileAddress).ownerOf(1), charlie);

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

        uint256 charliePk = 100;
        address charlie = vm.addr(charliePk);

        vm.mockCall(
            profileAddress,
            abi.encodeWithSelector(ERC721.ownerOf.selector, 1),
            abi.encode(charlie)
        );

        assertEq(ERC721(profileAddress).ownerOf(1), charlie);

        bytes[] memory subDatas = new bytes[](1);
        subDatas[0] = bytes("simple subdata");
        bool approved = true;

        vm.warp(50);
        uint256 deadline = 100;

        bytes32 digest = engine.hashTypedDataV4(
            keccak256(
                abi.encode(
                    Constants._SET_OPERATOR_APPROVAL_TYPEHASH,
                    profileId,
                    gov,
                    approved,
                    0,
                    deadline
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(charliePk, digest);

        vm.expectEmit(true, false, false, true);
        emit SetOperatorApproval(profileId, gov, approved);

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

        uint256 charliePk = 100;
        address charlie = vm.addr(charliePk);
        vm.mockCall(
            profileAddress,
            abi.encodeWithSelector(ERC721.ownerOf.selector, profileId),
            abi.encode(charlie)
        );
        assertEq(ERC721(profileAddress).ownerOf(profileId), charlie);

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

        vm.expectRevert("Invalid signature");
        engine.setMetadataWithSig(
            profileId,
            metadata,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
    }

    function testCannotSetMetadataAsNonOwnerAndOperator() public {
        vm.mockCall(
            profileAddress,
            abi.encodeWithSelector(ERC721.ownerOf.selector, profileId),
            abi.encode(address(0xDEAD))
        );
        vm.mockCall(
            profileAddress,
            abi.encodeWithSelector(
                IProfileNFT.getOperatorApproval.selector,
                profileId,
                address(this)
            ),
            abi.encode(false)
        );
        assertEq(ERC721(profileAddress).ownerOf(profileId), address(0xDEAD));
        assertEq(
            IProfileNFT(profileAddress).getOperatorApproval(
                profileId,
                address(this)
            ),
            false
        );
        vm.expectRevert("Only profile owner or operator");
        engine.setMetadata(profileId, "ipfs");
    }

    function testSetMetadataAsOperator() public {
        vm.mockCall(
            profileAddress,
            abi.encodeWithSelector(ERC721.ownerOf.selector, profileId),
            abi.encode(address(0xDEAD))
        );
        vm.mockCall(
            profileAddress,
            abi.encodeWithSelector(
                IProfileNFT.getOperatorApproval.selector,
                profileId,
                address(this)
            ),
            abi.encode(true)
        );
        assertEq(ERC721(profileAddress).ownerOf(profileId), address(0xDEAD));
        assertEq(
            IProfileNFT(profileAddress).getOperatorApproval(
                profileId,
                address(this)
            ),
            true
        );
        string memory metadata = "ipfs";
        vm.mockCall(
            profileAddress,
            abi.encodeWithSelector(
                IProfileNFT.setMetadata.selector,
                profileId,
                metadata
            ),
            abi.encode(0)
        );
        engine.setMetadata(profileId, metadata);
    }

    function testSetAvatarAsOwner() public {
        vm.prank(bob);
        vm.mockCall(
            profileAddress,
            abi.encodeWithSelector(ERC721.ownerOf.selector, profileId),
            abi.encode(bob)
        );
        engine.setAvatar(profileId, "avatar");
    }

    function testCannotSetAvatarAsNonOwnerAndOperator() public {
        vm.mockCall(
            profileAddress,
            abi.encodeWithSelector(ERC721.ownerOf.selector, profileId),
            abi.encode(address(0xDEAD))
        );
        vm.mockCall(
            profileAddress,
            abi.encodeWithSelector(
                IProfileNFT.getOperatorApproval.selector,
                profileId,
                address(this)
            ),
            abi.encode(false)
        );
        assertEq(ERC721(profileAddress).ownerOf(profileId), address(0xDEAD));
        assertEq(
            IProfileNFT(profileAddress).getOperatorApproval(
                profileId,
                address(this)
            ),
            false
        );
        vm.expectRevert("Only profile owner or operator");
        engine.setAvatar(profileId, "avatar");
    }

    function testSetAvatarAsOperator() public {
        vm.mockCall(
            profileAddress,
            abi.encodeWithSelector(ERC721.ownerOf.selector, profileId),
            abi.encode(address(0xDEAD))
        );
        vm.mockCall(
            profileAddress,
            abi.encodeWithSelector(
                IProfileNFT.getOperatorApproval.selector,
                profileId,
                address(this)
            ),
            abi.encode(true)
        );
        assertEq(ERC721(profileAddress).ownerOf(profileId), address(0xDEAD));
        assertEq(
            IProfileNFT(profileAddress).getOperatorApproval(
                profileId,
                address(this)
            ),
            true
        );
        string memory avatar = "avatar";
        vm.mockCall(
            profileAddress,
            abi.encodeWithSelector(
                IProfileNFT.setAvatar.selector,
                profileId,
                avatar
            ),
            abi.encode(0)
        );
        engine.setAvatar(profileId, avatar);
    }

    function testCannotSetSubscribeMwIfNotOwner() public {
        vm.mockCall(
            profileAddress,
            abi.encodeWithSelector(ERC721.ownerOf.selector, profileId),
            abi.encode(address(0xDEAD))
        );
        vm.expectRevert("Only profile owner");
        engine.setSubscribeMw(profileId, mw);
    }

    function testCannotSetSubscribeMwIfNotAllowed() public {
        vm.mockCall(
            profileAddress,
            abi.encodeWithSelector(ERC721.ownerOf.selector, profileId),
            abi.encode(bob)
        );
        vm.expectRevert("Subscribe middleware not allowed");
        address notMw = address(0xDEEAAAD);
        vm.prank(bob);
        engine.setSubscribeMw(profileId, notMw);
        assertEq(engine.getSubscribeMw(profileId), address(0));
    }

    function testSetSubscribeMw() public {
        vm.mockCall(
            profileAddress,
            abi.encodeWithSelector(ERC721.ownerOf.selector, profileId),
            abi.encode(bob)
        );
        vm.prank(bob);
        engine.setSubscribeMw(profileId, mw);
        assertEq(engine.getSubscribeMw(profileId), mw);
    }

    function testSetPrimary() public {
        vm.mockCall(
            profileAddress,
            abi.encodeWithSelector(ERC721.ownerOf.selector, profileId),
            abi.encode(bob)
        );
        vm.mockCall(
            profileAddress,
            abi.encodeWithSelector(
                IProfileNFT.setPrimaryProfile.selector,
                bob,
                profileId
            ),
            abi.encode(0)
        );

        vm.prank(bob);

        vm.expectEmit(true, true, false, true);
        emit SetPrimaryProfile(bob, profileId);
        engine.setPrimaryProfile(profileId);
    }

    function testCannotSetPrimaryAsNonOwner() public {
        vm.mockCall(
            profileAddress,
            abi.encodeWithSelector(ERC721.ownerOf.selector, profileId),
            abi.encode(alice)
        );

        vm.expectRevert("Only profile owner");
        vm.prank(bob);
        engine.setPrimaryProfile(profileId);
    }
}
