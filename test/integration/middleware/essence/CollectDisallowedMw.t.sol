// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";

import { LibDeploy } from "../../../../script/libraries/LibDeploy.sol";
import { DataTypes } from "../../../../src/libraries/DataTypes.sol";
import { Constants } from "../../../../src/libraries/Constants.sol";

import { IProfileNFTEvents } from "../../../../src/interfaces/IProfileNFTEvents.sol";
import { ICyberEngineEvents } from "../../../../src/interfaces/ICyberEngineEvents.sol";
import { CollectDisallowedMw } from "../../../../src/middlewares/essence/CollectDisallowedMw.sol";
import { TestIntegrationBase } from "../../../utils/TestIntegrationBase.sol";
import { EssenceNFT } from "../../../../src/core/EssenceNFT.sol";
import { TestLibFixture } from "../../../utils/TestLibFixture.sol";
import { TestLib712 } from "../../../utils/TestLib712.sol";

contract CollectDisallowedMwTest is
    TestIntegrationBase,
    ICyberEngineEvents,
    IProfileNFTEvents
{
    address lila = address(0x1114);
    string lilaHandle = "lila";
    uint256 lilaProfileId;

    address bobby = address(0xB0B);
    string bobbyHandle = "bobby";
    uint256 bobbyProfileId;

    address bobbyEssNFT;
    string constant BOBBY_ESSENCE_NAME = "Gaia";
    string constant BOBBY_ESSENCE_LABEL = "GA";
    string constant BOBBY_URL = "url";

    CollectDisallowedMw collectDisallowedMw;

    function setUp() public {
        _setUp();

        collectDisallowedMw = new CollectDisallowedMw();
        vm.label(address(collectDisallowedMw), "PaidCollectMw");

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
    }

    function testCannotCollectWithMiddleware() public {
        // allows the middleware
        vm.expectEmit(false, false, false, true);
        emit AllowEssenceMw(address(collectDisallowedMw), false, true);
        engine.allowEssenceMw(address(collectDisallowedMw), true);

        vm.expectEmit(true, true, false, false);
        emit RegisterEssence(
            bobbyProfileId,
            1,
            BOBBY_ESSENCE_NAME,
            BOBBY_ESSENCE_LABEL,
            BOBBY_URL,
            address(collectDisallowedMw),
            new bytes(0)
        );
        vm.prank(bobby);

        uint256 bobbyEssenceId = link3Profile.registerEssence(
            DataTypes.RegisterEssenceParams(
                bobbyProfileId,
                BOBBY_ESSENCE_NAME,
                BOBBY_ESSENCE_LABEL,
                BOBBY_URL,
                address(collectDisallowedMw),
                false
            ),
            new bytes(0)
        );

        vm.expectRevert("COLLECT_DISALLOWED");

        vm.prank(lila);
        link3Profile.collect(
            DataTypes.CollectParams(lila, bobbyProfileId, bobbyEssenceId),
            new bytes(0),
            new bytes(0)
        );
    }
}
