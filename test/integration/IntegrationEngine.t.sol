// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { TestIntegrationBase } from "../utils/TestIntegrationBase.sol";
import { DataTypes } from "../../src/libraries/DataTypes.sol";
import { LibDeploy } from "../../script/libraries/LibDeploy.sol";
import { ProfileNFT } from "../../src/core/ProfileNFT.sol";
import { ICyberEngineEvents } from "../../src/interfaces/ICyberEngineEvents.sol";
import { MockLink5NFTDescriptor } from "../utils/MockLink5NFTDescriptor.sol";

contract IntegrationEngineTest is TestIntegrationBase, ICyberEngineEvents {
    address namespaceOwner = alice;
    string constant LINK5_NAME = "Link5";
    string constant LINK5_SYMBOL = "L5";
    bytes32 constant LINK5_SALT = keccak256(bytes(LINK5_NAME));
    ProfileNFT link5Profile;

    function setUp() public {
        _setUp();
    }

    function testCreatNamespaceAndCreateAProfile() public {
        // don't check first arg in event
        vm.expectEmit(false, false, false, false);
        emit CreateNamespace(address(0), LINK5_NAME, LINK5_SYMBOL);
        address link5Namespace = LibDeploy.createNamespace(
            addrs.engineProxyAddress,
            namespaceOwner,
            LINK5_NAME,
            LINK5_SYMBOL,
            LINK5_SALT,
            addrs.essFac,
            addrs.subFac,
            addrs.profileFac
        );
        link5Profile = ProfileNFT(link5Namespace);
        assertEq(link5Profile.name(), LINK5_NAME);
        assertEq(link5Profile.symbol(), LINK5_SYMBOL);
        assertEq(link5Profile.totalSupply(), 0);

        // Create a profile
        vm.startPrank(bob);
        bytes memory data = new bytes(0);
        uint256 profileId = link5Profile.createProfile(
            DataTypes.CreateProfileParams(
                bob,
                "bob",
                "bob'avatar",
                "bob's metadata"
            ),
            data,
            data
        );
        assertEq(profileId, 1);
        assertEq(link5Profile.totalSupply(), 1);
        assertEq(link5Profile.balanceOf(bob), 1);
        assertEq(link5Profile.ownerOf(profileId), bob);
        vm.stopPrank();

        // set NFT descriptor
        vm.startPrank(namespaceOwner);

        link5Profile.setNFTDescriptor(address(new MockLink5NFTDescriptor()));
        assertEq(link5Profile.tokenURI(profileId), "Link5TokenURI");
        vm.stopPrank();
    }
}
