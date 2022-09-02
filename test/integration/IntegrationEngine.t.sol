// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ICyberEngineEvents } from "../../src/interfaces/ICyberEngineEvents.sol";
import { ICyberEngine } from "../../src/interfaces/ICyberEngine.sol";

import { DataTypes } from "../../src/libraries/DataTypes.sol";

import { TestIntegrationBase } from "../utils/TestIntegrationBase.sol";
import { LibDeploy } from "../../script/libraries/LibDeploy.sol";
import { ProfileNFT } from "../../src/core/ProfileNFT.sol";
import { EssenceNFT } from "../../src/core/EssenceNFT.sol";
import { SubscribeNFT } from "../../src/core/SubscribeNFT.sol";
import { UpgradeableBeacon } from "../../src/upgradeability/UpgradeableBeacon.sol";
import { MockLink5NFTDescriptor } from "../utils/MockLink5NFTDescriptor.sol";
import { MockProfileV2 } from "../utils/MockProfileV2.sol";
import { TestDeployer } from "../utils/TestDeployer.sol";

contract IntegrationEngineTest is
    TestIntegrationBase,
    ICyberEngineEvents,
    TestDeployer
{
    address namespaceOwner = alice;
    string constant LINK5_NAME = "Link5";
    string constant LINK5_SYMBOL = "L5";
    bytes32 constant LINK5_SALT = keccak256(bytes(LINK5_NAME));
    ProfileNFT link5Profile;

    function setUp() public {
        _setUp();
    }

    function testUpgradeSubscribeNFT() public {
        (address link5Namespace, address subBeacon, ) = LibDeploy
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

        SubscribeNFT subscribeNFTV2 = _deploySubV2(link5Namespace);
        ICyberEngine(addrs.engineProxyAddress).upgradeSubscribeNFT(
            address(subscribeNFTV2),
            link5Namespace
        );

        assertEq(
            UpgradeableBeacon(subBeacon).implementation(),
            address(subscribeNFTV2)
        );
    }

    function testUpgradeEssenceNFT() public {
        (address link5Namespace, , address essBeacon) = LibDeploy
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

        EssenceNFT essenceNFTV2 = _deployEssV2(link5Namespace);
        ICyberEngine(addrs.engineProxyAddress).upgradeEssenceNFT(
            address(essenceNFTV2),
            link5Namespace
        );

        assertEq(
            UpgradeableBeacon(essBeacon).implementation(),
            address(essenceNFTV2)
        );
    }

    function testUpgradeProfileNFT() public {
        (
            address link5Namespace,
            address subBeacon,
            address essBeacon
        ) = LibDeploy.createNamespace(
                addrs.engineProxyAddress,
                namespaceOwner,
                LINK5_NAME,
                LINK5_SYMBOL,
                LINK5_SALT,
                addrs.profileFac,
                addrs.subFac,
                addrs.essFac
            );

        ProfileNFT profileNFTV2 = _deployProfileV2(
            addrs.engineProxyAddress,
            essBeacon,
            subBeacon
        );
        assertEq(ProfileNFT(address(link5Namespace)).version(), 1);
        ICyberEngine(addrs.engineProxyAddress).upgradeProfileNFT(
            address(profileNFTV2),
            link5Namespace
        );

        assertEq(ProfileNFT(address(link5Namespace)).version(), 2);
    }

    function testCreatNamespaceAndCreateMultipleProfiles() public {
        // don't check first arg in event
        vm.expectEmit(false, false, false, false);
        emit CreateNamespace(address(0), LINK5_NAME, LINK5_SYMBOL);
        (address link5Namespace, , ) = LibDeploy.createNamespace(
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
        assertEq(link5Profile.name(), LINK5_NAME);
        assertEq(link5Profile.symbol(), LINK5_SYMBOL);
        assertEq(link5Profile.totalSupply(), 0);

        // Bob creates the first profile in Link5
        vm.startPrank(bob);
        bytes memory dataBob = new bytes(0);
        uint256 profileIdBob = link5Profile.createProfile(
            DataTypes.CreateProfileParams(
                bob,
                "bob",
                "bob'avatar",
                "bob's metadata",
                address(0)
            ),
            dataBob,
            dataBob
        );
        assertEq(profileIdBob, 1);
        assertEq(link5Profile.totalSupply(), 1);
        assertEq(link5Profile.balanceOf(bob), 1);
        assertEq(link5Profile.ownerOf(profileIdBob), bob);
        vm.stopPrank();

        // set NFT descriptor for Bob
        vm.startPrank(namespaceOwner);

        link5Profile.setNFTDescriptor(address(new MockLink5NFTDescriptor()));

        assertEq(link5Profile.tokenURI(profileIdBob), "Link5TokenURI");
        vm.stopPrank();

        // Carly creates another profile in Link5
        vm.startPrank(carly);
        bytes memory dataCarly = new bytes(0);
        uint256 profileIdCarly = link5Profile.createProfile(
            DataTypes.CreateProfileParams(
                carly,
                "realCarly",
                "carly'avatar",
                "carly's metadata",
                address(0)
            ),
            dataCarly,
            dataCarly
        );
        assertEq(profileIdCarly, 2);
        assertEq(link5Profile.totalSupply(), 2);
        assertEq(link5Profile.balanceOf(bob), 1);
        assertEq(link5Profile.ownerOf(profileIdCarly), carly);
        vm.stopPrank();

        // set NFT descriptor for Carly

        vm.startPrank(namespaceOwner);

        link5Profile.setNFTDescriptor(address(new MockLink5NFTDescriptor()));
        assertEq(link5Profile.tokenURI(profileIdCarly), "Link5TokenURI");
        vm.stopPrank();

        // Carly creates another profile under their address
        vm.startPrank(carly);
        bytes memory dataCarlyTwo = new bytes(0);
        uint256 profileIdCarlyTwo = link5Profile.createProfile(
            DataTypes.CreateProfileParams(
                carly,
                "Carly Second",
                "carly Second'avatar",
                "carly Second's metadata",
                address(0)
            ),
            dataCarlyTwo,
            dataCarlyTwo
        );
        assertEq(profileIdCarlyTwo, 3);
        assertEq(link5Profile.totalSupply(), 3);
        assertEq(link5Profile.balanceOf(carly), 2);
        assertEq(link5Profile.ownerOf(profileIdCarlyTwo), carly);
        vm.stopPrank();

        // set NFT descriptor for Carly's second profile

        vm.startPrank(namespaceOwner);

        link5Profile.setNFTDescriptor(address(new MockLink5NFTDescriptor()));
        assertEq(link5Profile.tokenURI(profileIdCarlyTwo), "Link5TokenURI");

        assertEq(link5Profile.tokenURI(profileIdBob), "Link5TokenURI");
        vm.stopPrank();
    }

    function _deploySubV2(address profile)
        internal
        returns (SubscribeNFT addr)
    {
        subParams.profileProxy = profile;
        addr = new SubscribeNFT{ salt: LINK5_SALT }();
        delete subParams;
    }

    function _deployEssV2(address profile) internal returns (EssenceNFT addr) {
        essParams.profileProxy = profile;
        addr = new EssenceNFT{ salt: LINK5_SALT }();
        delete essParams;
    }

    function _deployProfileV2(
        address engine,
        address essenceBeacon,
        address subscribeBeacon
    ) internal returns (ProfileNFT addr) {
        profileParams.engine = engine;
        profileParams.essenceBeacon = essenceBeacon;
        profileParams.subBeacon = subscribeBeacon;
        addr = new MockProfileV2{ salt: LINK5_SALT }();
        delete profileParams;
    }
}
