// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ERC721 } from "../../src/dependencies/solmate/ERC721.sol";
import { Base64 } from "../../src/dependencies/openzeppelin/Base64.sol";

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
        uint256 bobProfileId = TestLibFixture.registerBobProfile(
            vm,
            profile,
            profileMw,
            handle,
            to,
            link3SignerPk
        );

        uint256[] memory ids = new uint256[](1);
        ids[0] = bobProfileId;
        bytes[] memory data = new bytes[](1);

        uint256 nonce = vm.getNonce(address(profile));
        address subscribeProxy = LibDeploy._calcContractAddress(
            address(profile),
            nonce
        );

        vm.expectEmit(true, true, false, true, address(profile));
        emit DeploySubscribeNFT(ids[0], subscribeProxy);
        vm.expectEmit(true, false, false, true, address(profile));
        emit Subscribe(alice, ids, data, data);

        vm.prank(alice);
        uint256 nftid = profile.subscribe(
            DataTypes.SubscribeParams(ids),
            data,
            data
        )[0];

        // check bob sub nft supply
        address bobSubNFT = profile.getSubscribeNFT(bobProfileId);
        assertEq(CyberNFTBase(bobSubNFT).totalSupply(), 1);

        // check ownership of first sub nft
        assertEq(ERC721(bobSubNFT).ownerOf(nftid), address(alice));

        // alice subscribes again to bob
        vm.expectEmit(true, false, false, true, address(profile));
        emit Subscribe(alice, ids, data, data);
        vm.prank(alice);
        nftid = profile.subscribe(DataTypes.SubscribeParams(ids), data, data)[
            0
        ];

        // check bob sub nft supply
        assertEq(CyberNFTBase(bobSubNFT).totalSupply(), 2);
        assertEq(CyberNFTBase(bobSubNFT).balanceOf(alice), 2);

        // check ownership of second sub nft
        assertEq(ERC721(bobSubNFT).ownerOf(nftid), address(alice));
    }
}
