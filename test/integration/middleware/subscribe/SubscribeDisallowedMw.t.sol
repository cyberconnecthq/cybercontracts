// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";

import { IProfileNFTEvents } from "../../../../src/interfaces/IProfileNFTEvents.sol";

import { LibDeploy } from "../../../../script/libraries/LibDeploy.sol";
import { Constants } from "../../../../src/libraries/Constants.sol";
import { DataTypes } from "../../../../src/libraries/DataTypes.sol";

import { TestLibFixture } from "../../../utils/TestLibFixture.sol";
import { SubscribeDisallowedMw } from "../../../../src/middlewares/subscribe/SubscribeDisallowedMw.sol";
import { ProfileNFT } from "../../../../src/core/ProfileNFT.sol";
import { TestIntegrationBase } from "../../../utils/TestIntegrationBase.sol";

contract SubscribeDisallowedMwTest is TestIntegrationBase, IProfileNFTEvents {
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
    SubscribeDisallowedMw subDisallowedMw;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );

    function setUp() public {
        _setUp();

        // first allows the middleware
        subDisallowedMw = new SubscribeDisallowedMw();
        vm.label(address(subDisallowedMw), "SubscribeDisallowedMiddleware");
        engine.allowSubscribeMw(address(subDisallowedMw), true);

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

    function testSubscribeWithoutMiddleware() public {
        uint256[] memory ids = new uint256[](1);
        ids[0] = bobbyProfileId;
        bytes[] memory data = new bytes[](1);

        address subscribeProxy = getDeployedSubProxyAddress(
            link3SubBeacon,
            bobbyProfileId,
            address(link3Profile),
            bobbyHandle
        );

        console.log("subscribeProxy", subscribeProxy);

        vm.expectEmit(true, true, false, true, address(link3Profile));
        emit DeploySubscribeNFT(bobbyProfileId, subscribeProxy);

        vm.expectEmit(true, true, true, true, subscribeProxy);
        emit Transfer(address(0), lila, 1);

        vm.expectEmit(true, false, false, true, address(link3Profile));
        emit Subscribe(lila, ids, data, data);

        vm.prank(lila);
        link3Profile.subscribe(DataTypes.SubscribeParams(ids), data, data);

        assertEq(link3Profile.getSubscribeNFT(bobbyProfileId), subscribeProxy);
    }

    function testCannotSubscribeWithMiddleware() public {
        uint256[] memory ids = new uint256[](1);
        ids[0] = bobbyProfileId;
        bytes[] memory data = new bytes[](1);

        // bobby sets the subscribe middleware
        vm.prank(bobby);
        link3Profile.setSubscribeData(
            bobbyProfileId,
            "uri",
            address(subDisallowedMw),
            new bytes(0)
        );

        vm.prank(lila);
        vm.expectRevert("SUBSCRIBE_DISALLOWED");
        link3Profile.subscribe(DataTypes.SubscribeParams(ids), data, data);
    }
}
