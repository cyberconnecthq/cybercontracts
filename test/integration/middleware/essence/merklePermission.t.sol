// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";

import { LibDeploy } from "../../../../script/libraries/LibDeploy.sol";
import { DataTypes } from "../../../../src/libraries/DataTypes.sol";
import { Constants } from "../../../../src/libraries/Constants.sol";

import { IProfileNFTEvents } from "../../../../src/interfaces/IProfileNFTEvents.sol";
import { ICyberEngineEvents } from "../../../../src/interfaces/ICyberEngineEvents.sol";
import { MerklePermissionMw } from "../../../../src/middlewares/essence/MerklePermissionMw.sol";
import { TestIntegrationBase } from "../../../utils/TestIntegrationBase.sol";
import { EssenceNFT } from "../../../../src/core/EssenceNFT.sol";
import { TestLibFixture } from "../../../utils/TestLibFixture.sol";
import { TestLib712 } from "../../../utils/TestLib712.sol";

contract MerklePermissionTest is
    TestIntegrationBase,
    ICyberEngineEvents,
    IProfileNFTEvents
{
    address lila = 0xD68d2bD6f4a013A948881AC067282401b8f62FBb;
    address bobby = 0xE5D263Dd0D466EbF0Fc2647Dd4942a7525b0EAD1;
    address dave = 0xBDed9597195fb3C36b1A213cA45446906d7caeda;
    address MerkleEssenceProxy;
    address bobbyEssNFT;
    string lilaHandle = "lila";
    string bobbyHandle = "bobby";
    string constant BOBBY_ESSENCE_NAME = "Monolith";
    string constant BOBBY_ESSENCE_LABEL = "ML";
    string constant BOBBY_URL = "url";
    uint256 bobbyProfileId;
    uint256 lilaProfileId;
    uint256 bobbyEssenceId;

    bytes32 lilaLeaf = keccak256(abi.encode(lila));
    bytes32 bobbyLeaf = keccak256(abi.encode(bobby));
    bytes32 daveLeaf = keccak256(abi.encode(dave));

    bytes32 layer1 = _efficientHash(lilaLeaf, bobbyLeaf);

    bytes32 rootHash = _efficientHash(layer1, daveLeaf);

    // root and proof for testing
    bytes32 root = rootHash;
    bytes32[] proof = [bobbyLeaf, daveLeaf];

    MerklePermissionMw merkleMw;

    function setUp() public {
        _setUp();
        merkleMw = new MerklePermissionMw();
        vm.label(address(merkleMw), "MerkleMiddleware");

        // bob registeres for their profile
        bobbyProfileId = TestLibFixture.registerProfile(
            vm,
            link3Profile,
            profileMw,
            bobbyHandle,
            bobby,
            link3SignerPk
        );
        console.log("bobby id", bobbyProfileId);

        // lila registers for their profile
        lilaProfileId = TestLibFixture.registerProfile(
            vm,
            link3Profile,
            profileMw,
            lilaHandle,
            lila,
            link3SignerPk
        );

        console.log("lila id", lilaProfileId);

        // registers for essence, passes in the merkle hash root to set middleware data

        vm.expectEmit(false, false, false, true);
        emit AllowEssenceMw(address(merkleMw), false, true);
        engine.allowEssenceMw(address(merkleMw), true);

        vm.expectEmit(true, true, false, false);
        emit RegisterEssence(
            bobbyProfileId,
            1,
            BOBBY_ESSENCE_NAME,
            BOBBY_ESSENCE_LABEL,
            BOBBY_URL,
            address(merkleMw),
            abi.encodePacked(root)
        );

        vm.prank(bobby);
        bobbyEssenceId = link3Profile.registerEssence(
            DataTypes.RegisterEssenceParams(
                bobbyProfileId,
                BOBBY_ESSENCE_NAME,
                BOBBY_ESSENCE_LABEL,
                BOBBY_URL,
                address(merkleMw),
                false
            ),
            abi.encodePacked(root)
        );
        console.log("bobby essence", bobbyEssenceId);
    }

    function testMerklePermission() public {
        // lila wants to collect bob's essence
        vm.startPrank(lila);

        // predicts the addrs for the essenceNFT that is about to be deployed
        MerkleEssenceProxy = getDeployedEssProxyAddress(
            link3EssBeacon,
            bobbyProfileId,
            bobbyEssenceId,
            address(link3Profile),
            BOBBY_ESSENCE_NAME,
            BOBBY_ESSENCE_LABEL,
            false
        );

        console.log("essence proxy prediction", MerkleEssenceProxy);

        vm.expectEmit(true, true, true, false);
        emit DeployEssenceNFT(
            bobbyProfileId,
            bobbyEssenceId,
            MerkleEssenceProxy
        );

        vm.expectEmit(true, true, true, false);
        emit CollectEssence(
            lila,
            1,
            bobbyProfileId,
            abi.encode(proof),
            new bytes(0)
        );

        uint256 merkleTokenId = link3Profile.collect(
            DataTypes.CollectParams(lila, bobbyProfileId, bobbyEssenceId),
            abi.encode(proof),
            new bytes(0)
        );

        bobbyEssNFT = link3Profile.getEssenceNFT(
            bobbyProfileId,
            bobbyEssenceId
        );

        assertEq(bobbyEssNFT, MerkleEssenceProxy);
        assertEq(EssenceNFT(bobbyEssNFT).balanceOf(lila), 1);
        assertEq(EssenceNFT(bobbyEssNFT).ownerOf(merkleTokenId), lila);

        // check that dixon cannot collect becasue they are not on the list
    }

    function _efficientHash(bytes32 a, bytes32 b)
        internal
        pure
        returns (bytes32 value)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}
