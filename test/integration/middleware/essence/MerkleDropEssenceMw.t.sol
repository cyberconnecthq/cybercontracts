// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";

import { LibDeploy } from "../../../../script/libraries/LibDeploy.sol";
import { DataTypes } from "../../../../src/libraries/DataTypes.sol";
import { Constants } from "../../../../src/libraries/Constants.sol";

import { IProfileNFTEvents } from "../../../../src/interfaces/IProfileNFTEvents.sol";
import { ICyberEngineEvents } from "../../../../src/interfaces/ICyberEngineEvents.sol";
import { MerkleDropEssenceMw } from "../../../../src/middlewares/essence/MerkleDropEssenceMw.sol";
import { TestIntegrationBase } from "../../../utils/TestIntegrationBase.sol";
import { EssenceNFT } from "../../../../src/core/EssenceNFT.sol";
import { TestLibFixture } from "../../../utils/TestLibFixture.sol";
import { TestLib712 } from "../../../utils/TestLib712.sol";

contract MerkleDropEssenceMwTest is
    TestIntegrationBase,
    ICyberEngineEvents,
    IProfileNFTEvents
{
    address lila = 0xD68d2bD6f4a013A948881AC067282401b8f62FBb;
    address bobby = 0xE5D263Dd0D466EbF0Fc2647Dd4942a7525b0EAD1;
    address dave = 0xBDed9597195fb3C36b1A213cA45446906d7caeda;
    address ashley = 0x765E71Cb67069A0334E39992aB589F9F7DC73b8d;
    address casper = 0xcB9d710D5E72468A2ec4ba44232015d195cDF4Cd;
    address danny = 0xba8d695fe96C676593164ad31440A0975635D369;
    address andrew = 0xa826eC329B50D88EbE1ABB481aF28f35D22ACc2A;
    address denise = 0xD3ffA98133BBBD7f294bB07ed7Bf43C4e20CD481;

    address merkleEssenceProxy;
    address bobbyEssNFT;
    string lilaHandle = "lila";
    string bobbyHandle = "bobby";
    string constant BOBBY_ESSENCE_NAME = "Monolith";
    string constant BOBBY_ESSENCE_LABEL = "ML";
    string constant BOBBY_URL = "url";
    uint256 bobbyProfileId;
    uint256 lilaProfileId;
    uint256 bobbyEssenceId;

    // hard calculate the roots and leaves
    bytes32 lilaLeaf = keccak256(abi.encode(lila));
    bytes32 bobbyLeaf = keccak256(abi.encode(bobby));
    bytes32 daveLeaf = keccak256(abi.encode(dave));
    bytes32 ashleyLeaf = keccak256(abi.encode(ashley));
    bytes32 casperLeaf = keccak256(abi.encode(casper));
    bytes32 dannyLeaf = keccak256(abi.encode(danny));
    bytes32 andrewLeaf = keccak256(abi.encode(andrew));
    bytes32 deniseLeaf = keccak256(abi.encode(denise));

    bytes32 firstLayerNodeOne = _hashPair(lilaLeaf, bobbyLeaf);
    bytes32 firstLayerNodeTwo = _hashPair(daveLeaf, ashleyLeaf);
    bytes32 firstLayerNodeThree = _hashPair(casperLeaf, dannyLeaf);
    bytes32 firstLayerNodeFour = _hashPair(andrewLeaf, deniseLeaf);

    bytes32 secondLayerNodeOne =
        _hashPair(firstLayerNodeOne, firstLayerNodeTwo);
    bytes32 secondLayerNodeTwo =
        _hashPair(firstLayerNodeThree, firstLayerNodeFour);

    bytes32 rootHash = _hashPair(secondLayerNodeOne, secondLayerNodeTwo);

    bytes32 root = rootHash;
    bytes32[] proofForLila = [bobbyLeaf, firstLayerNodeTwo, secondLayerNodeTwo];

    MerkleDropEssenceMw merkleMw;

    function setUp() public {
        _setUp();
        merkleMw = new MerkleDropEssenceMw();
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

        // predicts the addrs for the essenceNFT that is about to be deployed
        merkleEssenceProxy = getDeployedEssProxyAddress(
            link3EssBeacon,
            bobbyProfileId,
            bobbyEssenceId,
            address(link3Profile),
            BOBBY_ESSENCE_NAME,
            BOBBY_ESSENCE_LABEL,
            false
        );
    }

    function testCollectwithCorrectProof() public {
        // lila wants to collect bob's essence
        vm.startPrank(lila);

        vm.expectEmit(true, true, true, false);
        emit DeployEssenceNFT(
            bobbyProfileId,
            bobbyEssenceId,
            merkleEssenceProxy
        );

        vm.expectEmit(true, true, true, false);
        emit CollectEssence(
            lila,
            1,
            bobbyProfileId,
            abi.encode(proofForLila),
            new bytes(0)
        );

        uint256 merkleTokenId = link3Profile.collect(
            DataTypes.CollectParams(lila, bobbyProfileId, bobbyEssenceId),
            abi.encode(proofForLila),
            new bytes(0)
        );

        bobbyEssNFT = link3Profile.getEssenceNFT(
            bobbyProfileId,
            bobbyEssenceId
        );

        assertEq(bobbyEssNFT, merkleEssenceProxy);
        assertEq(EssenceNFT(bobbyEssNFT).balanceOf(lila), 1);
        assertEq(EssenceNFT(bobbyEssNFT).ownerOf(merkleTokenId), lila);
    }

    function testCannotCollectWhenNotOnWhitelist() public {
        vm.expectRevert("INVALID_PROOF");
        vm.startPrank(lila);
        link3Profile.collect(
            DataTypes.CollectParams(ashley, bobbyProfileId, bobbyEssenceId),
            abi.encode(proofForLila),
            new bytes(0)
        );
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
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
