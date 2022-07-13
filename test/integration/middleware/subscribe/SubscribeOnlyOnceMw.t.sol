// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";

import { IProfileNFTEvents } from "../../../../src/interfaces/IProfileNFTEvents.sol";

import { LibDeploy } from "../../../../script/libraries/LibDeploy.sol";
import { Constants } from "../../../../src/libraries/Constants.sol";
import { DataTypes } from "../../../../src/libraries/DataTypes.sol";

import { TestLibFixture } from "../../../utils/TestLibFixture.sol";
import { SubscribeOnlyOnceMw } from "../../../../src/middlewares/subscribe/SubscribeOnlyOnceMw.sol";
import { ProfileNFT } from "../../../../src/core/ProfileNFT.sol";
import { TestIntegrationBase } from "../../../utils/TestIntegrationBase.sol";

contract SubscribeOnlyOnceMwTest is TestIntegrationBase, IProfileNFTEvents {
    uint256 bobProfileId;
    address profileDescriptorAddress;
    SubscribeOnlyOnceMw subMw;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );

    function setUp() public {
        _setUp();
        subMw = new SubscribeOnlyOnceMw();
        vm.label(address(subMw), "SubscribeMiddleware");
        string memory handle = "bob";
        address to = bob;

        bobProfileId = TestLibFixture.registerBobProfile(
            vm,
            profile,
            profileMw,
            handle,
            to,
            link3SignerPk
        );

        engine.allowSubscribeMw(address(subMw), true);
        vm.prank(bob);
        profile.setSubscribeMw(bobProfileId, address(subMw), new bytes(0));
    }

    function testSubscribeOnlyOnce() public {
        uint256[] memory ids = new uint256[](1);
        ids[0] = bobProfileId;
        bytes[] memory data = new bytes[](1);

        uint256 nonce = vm.getNonce(address(profile));
        address subscribeProxy = LibDeploy._calcContractAddress(
            address(profile),
            nonce
        );

        // TODO
        // vm.expectEmit(true, true, false, true);
        // emit DeploySubscribeNFT(bobProfileId, address(subscribeProxy));

        // vm.expectEmit(true, true, true, true);
        // emit Transfer(address(0), alice, 1);

        // vm.expectEmit(true, false, false, true);
        // emit Subscribe(alice, ids, data, data);

        vm.prank(alice);
        profile.subscribe(DataTypes.SubscribeParams(ids), data, data);

        // Second subscribe will fail
        vm.expectRevert("Already subscribed");
        vm.prank(alice);
        profile.subscribe(DataTypes.SubscribeParams(ids), data, data);
    }
}
