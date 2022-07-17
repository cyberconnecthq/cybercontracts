// SPDX-License-Identifier: GPL-3.0-or-later
import { ERC721 } from "../../src/dependencies/solmate/ERC721.sol";
import { Base64 } from "../../src/dependencies/openzeppelin/Base64.sol";

import { IProfileNFTEvents } from "../../src/interfaces/IProfileNFTEvents.sol";
import { ICyberEngineEvents } from "../../src/interfaces/ICyberEngineEvents.sol";
import { IEssenceMiddleware } from "../../src/interfaces/IEssenceMiddleware.sol";
import { IProfileDeployer } from "../../src/interfaces/IProfileDeployer.sol";

import { LibDeploy } from "../../script/libraries/LibDeploy.sol";
import { DataTypes } from "../../src/libraries/DataTypes.sol";
import { TestLib712 } from "../utils/TestLib712.sol";

import { CyberEngine } from "../../src/core/CyberEngine.sol";
import { CyberNFTBase } from "../../src/base/CyberNFTBase.sol";
import { ProfileNFT } from "../../src/core/ProfileNFT.sol";
import { SubscribeNFT } from "../../src/core/SubscribeNFT.sol";
import { TestLibFixture } from "../utils/TestLibFixture.sol";
import { LibString } from "../../src/libraries/LibString.sol";
import { Link3ProfileDescriptor } from "../../src/periphery/Link3ProfileDescriptor.sol";
import { PermissionedFeeCreationMw } from "../../src/middlewares/profile/PermissionedFeeCreationMw.sol";
import { TestIntegrationBase } from "../utils/TestIntegrationBase.sol";
import { ProfileNFTStorage } from "../../src/storages/ProfileNFTStorage.sol";
import { Actions } from "../../src/libraries/Actions.sol";
import { EssenceNFT } from "../../src/core/EssenceNFT.sol";
import { Constants } from "../../src/libraries/Constants.sol";

pragma solidity 0.8.14;

contract IntegrationEssenceTest is
    TestIntegrationBase,
    IProfileNFTEvents,
    ICyberEngineEvents,
    ProfileNFTStorage
{
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed id
    );

    address namespaceOwner = alice;
    string constant LINK5_NAME = "Link5";
    string constant LINK5_SYMBOL = "L5";
    bytes32 constant LINK5_SALT = keccak256(bytes(LINK5_NAME));
    string constant BOB_ESSENCE_NAME = "Arzuros Carapace";
    string constant BOB_ESSENCE_SYMBOL = "AC";
    address essenceMw = address(0); //change this
    uint256 profileIdBob;
    uint256 profileIdCarly;
    ProfileNFT link5Profile;
    bytes returnData = new bytes(111);
    bytes dataBobEssence = new bytes(0);
    address link5SubBeacon;
    address link5EssBeacon;

    uint256 bobEssenceId;

    string constant CARLY_ESSENCE_1_NAME = "Malzeno Fellwing";
    string constant CARLY_ESSENCE_1_SYMBOL = "MF";
    string constant CARLY_ESSENCE_1_URL = "mf.com";
    bool constant CARLY_ESSENCE_1_TRANSFERABLE = true;
    string constant CARLY_ESSENCE_2_NAME = "Nargacuga Tail";
    string constant CARLY_ESSENCE_2_SYMBOL = "NFT";
    string constant CARLY_ESSENCE_2_URL = "nt.com";
    bool constant CARLY_ESSENCE_2_TRANSFERABLE = false;
    uint256 carlyFirstEssenceId;
    uint256 carlyFirstEssenceTokenId; // bob mint this
    address carlyFirstEssenceAddr;
    uint256 carlySecondEssenceId;
    uint256 carlySecondEssenceTokenId; // bob mint this
    address carlySecondEssenceAddr;

    function setUp() public {
        // create an engine
        _setUp();
        address link5Namespace;
        (link5Namespace, link5SubBeacon, link5EssBeacon) = LibDeploy
            .createNamespace(
                addrs.engineProxyAddress,
                namespaceOwner,
                LINK5_NAME,
                LINK5_SYMBOL,
                LINK5_SALT,
                addrs.profileFac,
                addrs.subFac,
                addrs.essFac
            );

        link5Profile = ProfileNFT(link5Namespace);

        // create bob's profile
        vm.startPrank(bob);
        bytes memory dataBob = new bytes(0);
        profileIdBob = link5Profile.createProfile(
            DataTypes.CreateProfileParams(
                bob,
                "bob",
                "bob'avatar",
                "bob's metadata"
            ),
            dataBob,
            dataBob
        );
        //  bob register essence
        vm.expectEmit(true, true, false, false);
        emit RegisterEssence(
            profileIdBob,
            1,
            BOB_ESSENCE_NAME,
            BOB_ESSENCE_SYMBOL,
            "uri",
            essenceMw,
            returnData
        );

        // register essence with no essence middleware
        bobEssenceId = link5Profile.registerEssence(
            DataTypes.RegisterEssenceParams(
                profileIdBob,
                BOB_ESSENCE_NAME,
                BOB_ESSENCE_SYMBOL,
                "uri",
                essenceMw,
                true
            ),
            dataBobEssence
        );

        assertEq(
            link5Profile.getEssenceNFTTokenURI(profileIdBob, bobEssenceId),
            "uri"
        );

        vm.stopPrank();

        // create carly's profile
        vm.startPrank(carly);
        bytes memory dataCarly = new bytes(0);
        profileIdCarly = link5Profile.createProfile(
            DataTypes.CreateProfileParams(
                carly,
                "realCarly",
                "carly'avatar",
                "carly's metadata"
            ),
            dataCarly,
            dataCarly
        );
        // carly registers a transferable essence
        carlyFirstEssenceId = link5Profile.registerEssence(
            DataTypes.RegisterEssenceParams(
                profileIdCarly,
                CARLY_ESSENCE_1_NAME,
                CARLY_ESSENCE_1_SYMBOL,
                CARLY_ESSENCE_1_URL,
                address(0),
                CARLY_ESSENCE_1_TRANSFERABLE
            ),
            dataCarly
        );
        // carly registers a non-transferable essence
        carlySecondEssenceId = link5Profile.registerEssence(
            DataTypes.RegisterEssenceParams(
                profileIdCarly,
                CARLY_ESSENCE_2_NAME,
                CARLY_ESSENCE_2_SYMBOL,
                CARLY_ESSENCE_2_URL,
                address(0),
                CARLY_ESSENCE_2_TRANSFERABLE
            ),
            dataCarly
        );
        vm.stopPrank();

        // bob collects a both carly's essences #1
        vm.startPrank(bob);
        address essenceProxy;
        essenceProxy = getDeployedEssProxyAddress(
            link5EssBeacon,
            profileIdCarly,
            carlyFirstEssenceId,
            address(link5Profile),
            CARLY_ESSENCE_1_NAME,
            CARLY_ESSENCE_1_SYMBOL,
            CARLY_ESSENCE_1_TRANSFERABLE
        );
        carlyFirstEssenceTokenId = link5Profile.collect(
            DataTypes.CollectParams(bob, profileIdCarly, carlyFirstEssenceId),
            new bytes(0),
            new bytes(0)
        );
        carlyFirstEssenceAddr = link5Profile.getEssenceNFT(
            profileIdCarly,
            carlyFirstEssenceId
        );
        assertEq(carlyFirstEssenceAddr, essenceProxy);
        assertEq(
            EssenceNFT(carlyFirstEssenceAddr).name(),
            CARLY_ESSENCE_1_NAME
        );
        assertEq(
            EssenceNFT(carlyFirstEssenceAddr).symbol(),
            CARLY_ESSENCE_1_SYMBOL
        );
        assertEq(
            EssenceNFT(carlyFirstEssenceAddr).isTransferable(),
            CARLY_ESSENCE_1_TRANSFERABLE
        );
        assertEq(
            EssenceNFT(carlyFirstEssenceAddr).ownerOf(carlyFirstEssenceTokenId),
            bob
        );
        assertEq(EssenceNFT(carlyFirstEssenceAddr).balanceOf(bob), 1);

        // bob collects a both carly's essences #2
        essenceProxy = getDeployedEssProxyAddress(
            link5EssBeacon,
            profileIdCarly,
            carlySecondEssenceId,
            address(link5Profile),
            CARLY_ESSENCE_2_NAME,
            CARLY_ESSENCE_2_SYMBOL,
            CARLY_ESSENCE_2_TRANSFERABLE
        );
        carlySecondEssenceTokenId = link5Profile.collect(
            DataTypes.CollectParams(bob, profileIdCarly, carlySecondEssenceId),
            new bytes(0),
            new bytes(0)
        );
        carlySecondEssenceAddr = link5Profile.getEssenceNFT(
            profileIdCarly,
            carlySecondEssenceId
        );
        assertEq(carlySecondEssenceAddr, essenceProxy);
        assertEq(
            EssenceNFT(carlySecondEssenceAddr).name(),
            CARLY_ESSENCE_2_NAME
        );
        assertEq(
            EssenceNFT(carlySecondEssenceAddr).symbol(),
            CARLY_ESSENCE_2_SYMBOL
        );
        assertEq(
            EssenceNFT(carlySecondEssenceAddr).isTransferable(),
            CARLY_ESSENCE_2_TRANSFERABLE
        );
        assertEq(
            EssenceNFT(carlySecondEssenceAddr).ownerOf(
                carlySecondEssenceTokenId
            ),
            bob
        );
        assertEq(EssenceNFT(carlySecondEssenceAddr).balanceOf(bob), 1);

        vm.stopPrank();
    }

    function testCollect() public {
        // TODO: test for essence Mw
        // // Allow for EssenceMw
        // vm.expectEmit(false, false, false, true);
        // emit AllowEssenceMw(essenceMw, false, true);
        // engine.allowEssenceMw(essenceMw, true);

        // carly wants to collect bob's essence "Arzuros Carapace"
        vm.startPrank(carly);

        address essenceProxy = getDeployedEssProxyAddress(
            link5EssBeacon,
            profileIdBob,
            bobEssenceId,
            address(link5Profile),
            BOB_ESSENCE_NAME,
            BOB_ESSENCE_SYMBOL,
            true
        );
        vm.expectEmit(true, true, false, true);
        emit DeployEssenceNFT(profileIdBob, bobEssenceId, essenceProxy);

        vm.expectEmit(true, true, false, false);
        emit CollectEssence(carly, 1, profileIdBob, new bytes(0), new bytes(0));

        uint256 tokenId = link5Profile.collect(
            DataTypes.CollectParams(carly, profileIdBob, bobEssenceId),
            new bytes(0),
            new bytes(0)
        );

        assertEq(tokenId, 1);
        assertEq(
            link5Profile.getEssenceNFT(profileIdBob, bobEssenceId),
            essenceProxy
        );
        assertEq(EssenceNFT(essenceProxy).balanceOf(carly), 1);
        assertEq(EssenceNFT(essenceProxy).ownerOf(bobEssenceId), carly);
        vm.stopPrank();
    }

    function testCollectToSomeoneElse() public {
        // carly collect to dixon
        vm.startPrank(carly);

        address essenceProxy = getDeployedEssProxyAddress(
            link5EssBeacon,
            profileIdBob,
            bobEssenceId,
            address(link5Profile),
            BOB_ESSENCE_NAME,
            BOB_ESSENCE_SYMBOL,
            true
        );

        vm.expectEmit(true, true, false, true);
        emit DeployEssenceNFT(profileIdBob, bobEssenceId, essenceProxy);

        vm.expectEmit(true, true, false, false);
        emit CollectEssence(dixon, 1, profileIdBob, new bytes(0), new bytes(0));

        uint256 tokenId = link5Profile.collect(
            DataTypes.CollectParams(dixon, profileIdBob, bobEssenceId),
            new bytes(0),
            new bytes(0)
        );

        assertEq(tokenId, 1);
        assertEq(
            link5Profile.getEssenceNFT(profileIdBob, bobEssenceId),
            essenceProxy
        );
        assertEq(EssenceNFT(essenceProxy).balanceOf(dixon), 1);
        assertEq(EssenceNFT(essenceProxy).ownerOf(bobEssenceId), dixon);
        vm.stopPrank();
    }

    function testCollectWithSig() public {
        // bob signs and carly sends tx to collect to bob
        address essenceProxy = getDeployedEssProxyAddress(
            link5EssBeacon,
            profileIdBob,
            bobEssenceId,
            address(link5Profile),
            BOB_ESSENCE_NAME,
            BOB_ESSENCE_SYMBOL,
            true
        );
        vm.expectEmit(true, true, false, true);
        emit DeployEssenceNFT(profileIdBob, bobEssenceId, essenceProxy);

        vm.expectEmit(true, true, false, false);
        emit CollectEssence(bob, 1, profileIdBob, new bytes(0), new bytes(0));

        uint256 deadline = 100;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            bobPk,
            TestLib712.hashTypedDataV4(
                address(link5Profile),
                keccak256(
                    abi.encode(
                        Constants._COLLECT_TYPEHASH,
                        bob,
                        profileIdBob,
                        bobEssenceId,
                        keccak256(new bytes(0)),
                        keccak256(new bytes(0)),
                        link5Profile.nonces(bob),
                        deadline
                    )
                ),
                link5Profile.name(),
                "1"
            )
        );
        vm.startPrank(carly);
        uint256 tokenId = link5Profile.collectWithSig(
            DataTypes.CollectParams(bob, profileIdBob, bobEssenceId),
            new bytes(0),
            new bytes(0),
            bob,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
        assertEq(tokenId, 1);
        assertEq(
            link5Profile.getEssenceNFT(profileIdBob, bobEssenceId),
            essenceProxy
        );
        assertEq(EssenceNFT(essenceProxy).balanceOf(bob), 1);
        assertEq(EssenceNFT(essenceProxy).ownerOf(bobEssenceId), bob);
        vm.stopPrank();
    }

    function testCollectWithSigToSomeoneElse() public {
        // bob signs and carly sends tx to collect to dixon
        address essenceProxy = getDeployedEssProxyAddress(
            link5EssBeacon,
            profileIdBob,
            bobEssenceId,
            address(link5Profile),
            BOB_ESSENCE_NAME,
            BOB_ESSENCE_SYMBOL,
            true
        );
        vm.expectEmit(true, true, false, true);
        emit DeployEssenceNFT(profileIdBob, bobEssenceId, essenceProxy);

        vm.expectEmit(true, true, false, false);
        emit CollectEssence(dixon, 1, profileIdBob, new bytes(0), new bytes(0));

        uint256 deadline = 100;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            bobPk,
            TestLib712.hashTypedDataV4(
                address(link5Profile),
                keccak256(
                    abi.encode(
                        Constants._COLLECT_TYPEHASH,
                        dixon,
                        profileIdBob,
                        bobEssenceId,
                        keccak256(new bytes(0)),
                        keccak256(new bytes(0)),
                        link5Profile.nonces(bob),
                        deadline
                    )
                ),
                link5Profile.name(),
                "1"
            )
        );
        vm.startPrank(carly);
        uint256 tokenId = link5Profile.collectWithSig(
            DataTypes.CollectParams(dixon, profileIdBob, bobEssenceId),
            new bytes(0),
            new bytes(0),
            bob,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
        assertEq(tokenId, 1);
        assertEq(
            link5Profile.getEssenceNFT(profileIdBob, bobEssenceId),
            essenceProxy
        );
        assertEq(EssenceNFT(essenceProxy).balanceOf(dixon), 1);
        assertEq(EssenceNFT(essenceProxy).ownerOf(bobEssenceId), dixon);
        vm.stopPrank();
    }

    function testEssenceTransfer() public {
        EssenceNFT essence = EssenceNFT(carlyFirstEssenceAddr);
        vm.prank(bob);
        essence.transferFrom(bob, alice, carlyFirstEssenceTokenId);
        assertEq(essence.balanceOf(bob), 0);
        assertEq(essence.balanceOf(alice), 1);
        assertEq(essence.ownerOf(carlyFirstEssenceTokenId), alice);
    }

    function testEssencePermitAndTransfer() public {
        // permit
        EssenceNFT essence = EssenceNFT(carlyFirstEssenceAddr);
        vm.warp(50);
        uint256 deadline = 100;
        bytes32 data = keccak256(
            abi.encode(
                Constants._PERMIT_TYPEHASH,
                alice,
                carlyFirstEssenceTokenId,
                essence.nonces(bob),
                deadline
            )
        );
        bytes32 digest = TestLib712.hashTypedDataV4(
            address(essence),
            data,
            CARLY_ESSENCE_1_NAME,
            "1"
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(bobPk, digest);
        emit Approval(bob, alice, carlyFirstEssenceTokenId);
        essence.permit(
            alice,
            carlyFirstEssenceTokenId,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
        assertEq(essence.getApproved(carlyFirstEssenceTokenId), alice);
        // transfer
        vm.prank(alice);
        essence.transferFrom(bob, alice, carlyFirstEssenceTokenId);
        assertEq(essence.balanceOf(bob), 0);
        assertEq(essence.balanceOf(alice), 1);
        assertEq(essence.ownerOf(carlyFirstEssenceTokenId), alice);
    }

    function testCannotTransferNonTransferableEssence() public {
        EssenceNFT essence = EssenceNFT(carlySecondEssenceAddr);
        vm.prank(bob);
        vm.expectRevert("TRANSFER_NOT_ALLOWED");
        essence.transferFrom(bob, alice, carlySecondEssenceTokenId);
        assertEq(essence.balanceOf(bob), 1);
        assertEq(essence.balanceOf(alice), 0);
        assertEq(essence.ownerOf(carlySecondEssenceTokenId), bob);
    }

    function testCannotPermitAndTransferNonTransferableEssence() public {
        // permit
        EssenceNFT essence = EssenceNFT(carlySecondEssenceAddr);
        vm.warp(50);
        uint256 deadline = 100;
        bytes32 data = keccak256(
            abi.encode(
                Constants._PERMIT_TYPEHASH,
                alice,
                carlySecondEssenceTokenId,
                essence.nonces(bob),
                deadline
            )
        );
        bytes32 digest = TestLib712.hashTypedDataV4(
            address(essence),
            data,
            CARLY_ESSENCE_2_NAME,
            "1"
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(bobPk, digest);
        emit Approval(bob, alice, carlySecondEssenceTokenId);
        essence.permit(
            alice,
            carlySecondEssenceTokenId,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
        assertEq(essence.getApproved(carlySecondEssenceTokenId), alice);
        // transfer initiated by permitted address
        vm.prank(bob);
        vm.expectRevert("TRANSFER_NOT_ALLOWED");
        essence.transferFrom(bob, alice, carlySecondEssenceTokenId);
        assertEq(essence.balanceOf(bob), 1);
        assertEq(essence.balanceOf(alice), 0);
        assertEq(essence.ownerOf(carlySecondEssenceTokenId), bob);
    }
}
