// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";

import { LibDeploy } from "../../../../script/libraries/LibDeploy.sol";
import { DataTypes } from "../../../../src/libraries/DataTypes.sol";
import { Constants } from "../../../../src/libraries/Constants.sol";

import { IProfileNFTEvents } from "../../../../src/interfaces/IProfileNFTEvents.sol";
import { ICyberEngineEvents } from "../../../../src/interfaces/ICyberEngineEvents.sol";
import { SignaturePermissionEssenceMw } from "../../../../src/middlewares/essence/SignaturePermissionEssenceMw.sol";
import { TestIntegrationBase } from "../../../utils/TestIntegrationBase.sol";
import { EssenceNFT } from "../../../../src/core/EssenceNFT.sol";
import { TestLibFixture } from "../../../utils/TestLibFixture.sol";
import { TestLib712 } from "../../../utils/TestLib712.sol";

contract SignaturePermissionEssenceMwTest is
    TestIntegrationBase,
    ICyberEngineEvents,
    IProfileNFTEvents
{
    // note: logic:
    // Pk means private key
    // Only users approved by the essence owner's private key has the the correct sig
    // 1. message(digest) + Pk = Signature
    // Then the middleware verifies whether the message(digest) + the sig = the essence'
    // owners address(can be derived from public key)
    // 2. message(digest) + Signature = public key => address

    bytes32 internal constant _ESSENCE_TYPEHASH =
        keccak256("mint(address to,uint256 nonce,uint256 deadline)");
    uint256 lilaPk = 1024;
    address lila = vm.addr(lilaPk);
    uint256 bobbyPk = 2048;
    address bobby = vm.addr(bobbyPk);
    uint256 davePk = 4096;
    address dave = vm.addr(davePk);
    uint256 validDeadline;
    uint256 exceededTime;

    address sigPermissionEssenceProxy;
    uint256 bobbyEssenceId;
    address bobbyEssNFT;
    string lilaHandle = "lila";
    string bobbyHandle = "bobby";
    string constant BOBBY_ESSENCE_NAME = "Gaia";
    string constant BOBBY_ESSENCE_LABEL = "GA";
    string constant BOBBY_URL = "url";
    uint256 bobbyProfileId;
    uint256 lilaProfileId;

    SignaturePermissionEssenceMw sigMw;

    function setUp() public {
        validDeadline = block.timestamp + 100;
        exceededTime = 300;

        _setUp();
        sigMw = new SignaturePermissionEssenceMw();
        vm.label(address(sigMw), "SignaturePermissionMiddleware");

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

        vm.expectEmit(false, false, false, true);
        emit AllowEssenceMw(address(sigMw), false, true);
        engine.allowEssenceMw(address(sigMw), true);

        vm.expectEmit(true, true, false, false);
        emit RegisterEssence(
            bobbyProfileId,
            1,
            BOBBY_ESSENCE_NAME,
            BOBBY_ESSENCE_LABEL,
            BOBBY_URL,
            address(sigMw),
            abi.encode(bobby)
        );

        vm.prank(bobby);
        bobbyEssenceId = link3Profile.registerEssence(
            DataTypes.RegisterEssenceParams(
                bobbyProfileId,
                BOBBY_ESSENCE_NAME,
                BOBBY_ESSENCE_LABEL,
                BOBBY_URL,
                address(sigMw),
                false,
                false
            ),
            abi.encode(bobby)
        );

        // predicts the addrs for the essenceNFT that is about to be deployed
        sigPermissionEssenceProxy = getDeployedEssProxyAddress(
            link3EssBeacon,
            bobbyProfileId,
            bobbyEssenceId,
            address(link3Profile),
            BOBBY_ESSENCE_NAME,
            BOBBY_ESSENCE_LABEL,
            false
        );
    }

    function testCollectWithCorrectSig() public {
        // lila wants to collect bob's essence
        vm.startPrank(lila);

        // need collector(lila)'s address, the essence owner(bobby, signer)'s private key
        // deadline. we store the nonce info under bobby's profile id and the essence id in the middleware mapping
        // same as bobby approving lila's identity by signing with their private key
        (uint8 v, bytes32 r, bytes32 s) = _generateValidSig(
            lila,
            bobbyPk,
            validDeadline,
            bobbyProfileId,
            bobbyEssenceId
        );

        vm.expectEmit(true, true, true, false);
        emit DeployEssenceNFT(
            bobbyProfileId,
            bobbyEssenceId,
            sigPermissionEssenceProxy
        );

        vm.expectEmit(true, true, true, false);
        emit CollectEssence(
            lila,
            bobbyProfileId,
            bobbyEssenceId,
            1,
            abi.encode(v, r, s, validDeadline),
            new bytes(0)
        );

        uint256 EssTokenId = link3Profile.collect(
            DataTypes.CollectParams(lila, bobbyProfileId, bobbyEssenceId),
            abi.encode(v, r, s, validDeadline),
            new bytes(0)
        );

        bobbyEssNFT = link3Profile.getEssenceNFT(
            bobbyProfileId,
            bobbyEssenceId
        );

        assertEq(bobbyEssNFT, sigPermissionEssenceProxy);
        assertEq(EssenceNFT(bobbyEssNFT).balanceOf(lila), 1);
        assertEq(EssenceNFT(bobbyEssNFT).ownerOf(EssTokenId), lila);
    }

    function testCannotCollectWithWrongSig() public {
        vm.startPrank(lila);

        // uses dave's private key to generate sig(dave signs), whose not the rightful owener
        (uint8 v, bytes32 r, bytes32 s) = _generateValidSig(
            lila,
            davePk,
            validDeadline,
            bobbyProfileId,
            bobbyEssenceId
        );

        vm.expectRevert("INVALID_SIGNATURE");
        link3Profile.collect(
            DataTypes.CollectParams(lila, bobbyProfileId, bobbyEssenceId),
            abi.encode(v, r, s, validDeadline),
            new bytes(0)
        );
    }

    function testCannotCollectBeyondDeadline() public {
        vm.startPrank(lila);
        (uint8 v, bytes32 r, bytes32 s) = _generateValidSig(
            lila,
            bobbyPk,
            validDeadline,
            bobbyProfileId,
            bobbyEssenceId
        );

        skip(exceededTime);

        vm.expectRevert("DEADLINE_EXCEEDED");
        link3Profile.collect(
            DataTypes.CollectParams(lila, bobbyProfileId, bobbyEssenceId),
            abi.encode(v, r, s, validDeadline),
            new bytes(0)
        );
    }

    function _generateValidSig(
        address collector,
        uint256 signerPk,
        uint256 deadline,
        uint256 profileId,
        uint256 essenceId
    )
        internal
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        uint256 nonce = sigMw.getNonce(profileId, essenceId);
        bytes32 digest = TestLib712.hashTypedDataV4(
            address(sigMw),
            keccak256(
                abi.encode(_ESSENCE_TYPEHASH, collector, nonce, deadline)
            ),
            "SignaturePermissionEssenceMw",
            "1"
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, digest);
        return (v, r, s);
    }
}
