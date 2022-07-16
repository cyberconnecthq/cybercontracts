// SPDX-License-Identifier: GPL-3.0-or-later
import { ERC721 } from "../../src/dependencies/solmate/ERC721.sol";
import { Base64 } from "../../src/dependencies/openzeppelin/Base64.sol";

import { IProfileNFTEvents } from "../../src/interfaces/IProfileNFTEvents.sol";
import { ICyberEngineEvents } from "../../src/interfaces/ICyberEngineEvents.sol";
import { IEssenceMiddleware } from "../../src/interfaces/IEssenceMiddleware.sol";
import { IProfileDeployer } from "../../src/interfaces/IProfileDeployer.sol";

import { LibDeploy } from "../../script/libraries/LibDeploy.sol";
import { DataTypes } from "../../src/libraries/DataTypes.sol";

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

pragma solidity 0.8.14;

contract IntegrationCollectTest is
    TestIntegrationBase,
    IProfileNFTEvents,
    ICyberEngineEvents,
    ProfileNFTStorage
{
    address namespaceOwner = alice;
    string constant LINK5_NAME = "Link5";
    string constant LINK5_SYMBOL = "L5";
    bytes32 constant LINK5_SALT = keccak256(bytes(LINK5_NAME));
    string constant ESSENCE_NAME = "Arzuros Carapace";
    string constant ESSENCE_SYMBOL = "AC";
    address essenceMw = address(0); //change this
    uint256 profileIdBob;
    uint256 profileIdCarly;
    ProfileNFT link5Profile;
    bytes returnData = new bytes(111);
    bytes dataBobEssence = new bytes(0);
    address link5SubBeacon;
    address link5EssBeacon;

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
        vm.stopPrank();
    }

    function testCollect() public {
        // TODO: test for essence Mw
        // // Allow for EssenceMw
        // vm.expectEmit(false, false, false, true);
        // emit AllowEssenceMw(essenceMw, false, true);
        // engine.allowEssenceMw(essenceMw, true);
        vm.startPrank(bob);
        vm.expectEmit(true, true, false, false);
        emit RegisterEssence(
            profileIdBob,
            1,
            ESSENCE_NAME,
            ESSENCE_SYMBOL,
            "uri",
            essenceMw,
            returnData
        );

        // register essence with no essence middleware
        uint256 essenceId = link5Profile.registerEssence(
            DataTypes.RegisterEssenceParams(
                profileIdBob,
                ESSENCE_NAME,
                ESSENCE_SYMBOL,
                "uri",
                essenceMw
            ),
            dataBobEssence
        );

        assertEq(
            link5Profile.getEssenceNFTTokenURI(profileIdBob, essenceId),
            "uri"
        );

        vm.stopPrank();

        // carly wants to collect bob's essence "Arzuros Carapace"
        vm.startPrank(carly);
        vm.expectEmit(true, true, false, false);
        emit CollectEssence(carly, 1, profileIdBob, new bytes(0), new bytes(0));

        address essenceProxy = getDeployedEssProxyAddress(
            link5EssBeacon,
            profileIdBob,
            essenceId,
            address(link5Profile),
            ESSENCE_NAME,
            ESSENCE_SYMBOL
        );

        uint256 tokenId = link5Profile.collect(
            DataTypes.CollectParams(profileIdBob, essenceId),
            new bytes(0),
            new bytes(0)
        );

        assertEq(tokenId, 1);
        assertEq(
            link5Profile.getEssenceNFT(profileIdBob, essenceId),
            essenceProxy
        );
        assertEq(EssenceNFT(essenceProxy).balanceOf(carly), 1);
        assertEq(EssenceNFT(essenceProxy).ownerOf(essenceId), carly);
    }
}
