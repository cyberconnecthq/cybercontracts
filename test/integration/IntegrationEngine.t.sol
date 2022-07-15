// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { TestIntegrationBase } from "../utils/TestIntegrationBase.sol";
import { DataTypes } from "../../src/libraries/DataTypes.sol";
import { LibDeploy } from "../../script/libraries/LibDeploy.sol";
import { ProfileNFT } from "../../src/core/ProfileNFT.sol";
import { ICyberEngineEvents } from "../../src/interfaces/ICyberEngineEvents.sol";
import { MockLink5NFTDescriptor } from "../utils/MockLink5NFTDescriptor.sol";
import { CyberEngine } from "../../src/core/CyberEngine.sol";

contract IntegrationEngineTest is TestIntegrationBase, ICyberEngineEvents {
    address namespaceOwner = alice;
    string constant LINK5_NAME = "Link5";
    string constant LINK5_SYMBOL = "L5";
    bytes32 constant LINK5_SALT = keccak256(bytes(LINK5_NAME));
    ProfileNFT link5Profile;

    function setUp() public {
        _setUp();
    }

    function testCreatNamespaceAndCreateMultipleProfiles() public {
        // don't check first arg in event
        vm.expectEmit(false, false, false, false);
        emit CreateNamespace(address(0), LINK5_NAME, LINK5_SYMBOL);
        address link5Namespace = LibDeploy.createNamespace(
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
                "bob's metadata"
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
                "carly's metadata"
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
                "carly Second's metadata"
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

        vm.stopPrank();
    }
}
