// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ERC721 } from "../../src/dependencies/solmate/ERC721.sol";
import { Base64 } from "openzeppelin-contracts/contracts/utils/Base64.sol";

import { IProfileNFTEvents } from "../../src/interfaces/IProfileNFTEvents.sol";

import { LibDeploy } from "../../script/libraries/LibDeploy.sol";
import { DataTypes } from "../../src/libraries/DataTypes.sol";

import { CyberNFTBase } from "../../src/base/CyberNFTBase.sol";
import { ProfileNFT } from "../../src/core/ProfileNFT.sol";
import { SubscribeNFT } from "../../src/core/SubscribeNFT.sol";
import { TestLibFixture } from "../utils/TestLibFixture.sol";
import { LibString } from "../../src/libraries/LibString.sol";
import { Link3ProfileDescriptor } from "../../src/periphery/Link3ProfileDescriptor.sol";
import { PermissionedFeeCreationMw } from "../../src/middlewares/profile/PermissionedFeeCreationMw.sol";
import { TestIntegrationBase } from "../utils/TestIntegrationBase.sol";

contract IntegrationSubscribeTest is TestIntegrationBase, IProfileNFTEvents {
    function setUp() public {
        _setUp();
    }

    function testSubscription() public {
        string memory handle = "bob";
        address to = bob;
        uint256 bobProfileId = TestLibFixture.registerProfile(
            vm,
            link3Profile,
            profileMw,
            handle,
            to,
            link3SignerPk
        );

        uint256[] memory ids = new uint256[](1);
        ids[0] = bobProfileId;
        bytes[] memory data = new bytes[](1);

        address subscribeProxy = getDeployedSubProxyAddress(
            addrs.subBeacon,
            bobProfileId,
            address(link3Profile),
            handle
        );

        vm.expectEmit(true, true, false, true, address(link3Profile));
        emit DeploySubscribeNFT(ids[0], subscribeProxy);
        vm.expectEmit(true, false, false, true, address(link3Profile));
        emit Subscribe(alice, ids, data, data);

        vm.prank(alice);
        uint256 nftid = link3Profile.subscribe(
            DataTypes.SubscribeParams(ids),
            data,
            data
        )[0];

        // check bob sub nft supply
        address bobSubNFT = link3Profile.getSubscribeNFT(bobProfileId);
        assertEq(bobSubNFT, subscribeProxy);
        assertEq(CyberNFTBase(bobSubNFT).totalSupply(), 1);

        // check ownership of first sub nft
        assertEq(ERC721(bobSubNFT).ownerOf(nftid), address(alice));

        // alice subscribes again to bob
        vm.expectEmit(true, false, false, true, address(link3Profile));
        emit Subscribe(alice, ids, data, data);
        vm.prank(alice);
        nftid = link3Profile.subscribe(
            DataTypes.SubscribeParams(ids),
            data,
            data
        )[0];

        // check bob sub nft supply
        assertEq(CyberNFTBase(bobSubNFT).totalSupply(), 2);
        assertEq(CyberNFTBase(bobSubNFT).balanceOf(alice), 2);

        // check ownership of second sub nft
        assertEq(ERC721(bobSubNFT).ownerOf(nftid), address(alice));
    }

    function subscribeToTwoProfileFromTwoWallet() public {
        string memory bobHandle = "bob";
        uint256 bobProfileId = TestLibFixture.registerProfile(
            vm,
            link3Profile,
            profileMw,
            bobHandle,
            bob,
            link3SignerPk
        );

        string memory aliceHandle = "alice";
        uint256 aliceProfileId = TestLibFixture.registerProfile(
            vm,
            link3Profile,
            profileMw,
            aliceHandle,
            alice,
            link3SignerPk
        );

        // charlie subscribes to alice and bob
        vm.startPrank(carly);

        uint256[] memory ids = new uint256[](2);
        ids[0] = aliceProfileId;
        ids[1] = bobProfileId;
        bytes[] memory data = new bytes[](2);

        address aliceSubProxy = getDeployedSubProxyAddress(
            addrs.subBeacon,
            aliceProfileId,
            address(link3Profile),
            aliceHandle
        );

        address bobSubProxy = getDeployedSubProxyAddress(
            addrs.subBeacon,
            bobProfileId,
            address(link3Profile),
            bobHandle
        );

        vm.expectEmit(true, true, false, true, address(link3Profile));
        emit DeploySubscribeNFT(ids[0], aliceSubProxy);

        vm.expectEmit(true, true, false, true, address(link3Profile));
        emit DeploySubscribeNFT(ids[1], bobSubProxy);

        vm.expectEmit(true, false, false, true, address(link3Profile));
        emit Subscribe(alice, ids, data, data);

        link3Profile.subscribe(DataTypes.SubscribeParams(ids), data, data);
        assertEq(link3Profile.getSubscribeNFT(aliceProfileId), aliceSubProxy);
        assertEq(link3Profile.getSubscribeNFT(bobProfileId), bobSubProxy);

        vm.stopPrank();

        // dixon subscribes to alice to bob
        vm.startPrank(dixon);

        vm.expectEmit(true, false, false, true, address(link3Profile));
        emit Subscribe(bob, ids, data, data);

        link3Profile.subscribe(DataTypes.SubscribeParams(ids), data, data);

        vm.stopPrank();
    }
}
