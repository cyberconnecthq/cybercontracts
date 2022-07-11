// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;
import "forge-std/Test.sol";
import { LibDeploy } from "../../script/libraries/LibDeploy.sol";
import { CyberNFTBase } from "../../src/base/CyberNFTBase.sol";
import { ProfileNFT } from "../../src/core/ProfileNFT.sol";
import { RolesAuthority } from "../../src/dependencies/solmate/RolesAuthority.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IProfileNFTEvents } from "../../src/interfaces/IProfileNFTEvents.sol";
import { SubscribeNFT } from "../../src/core/SubscribeNFT.sol";
import { TestLibFixture } from "../utils/TestLibFixture.sol";
import { Base64 } from "../../src/dependencies/openzeppelin/Base64.sol";
import { LibString } from "../../src/libraries/LibString.sol";
import { ERC721 } from "../../src/dependencies/solmate/ERC721.sol";

contract SubscribeTest is Test, IProfileNFTEvents {
    RolesAuthority authority;
    address boxAddress;
    address profileAddress;
    address alice = address(0xA11CE);
    uint256 bobPk = 1;
    address bob = vm.addr(bobPk);
    uint256 bobProfileId;
    address profileDescriptorAddress;
    ProfileNFT profile;

    function setUp() public {
        uint256 nonce = vm.getNonce(address(this));
        address proxy;
        (
            proxy,
            authority,
            boxAddress,
            profileAddress,
            profileDescriptorAddress
        ) = LibDeploy.deploy(
            address(this),
            nonce,
            "https://animation.example.com"
        );
        TestLibFixture.auth(authority);
        profile = ProfileNFT(address(profileAddress));
        bobProfileId = TestLibFixture.registerBobProfile(profile);
        TestLibFixture.auth(authority);
    }

    // test sub without sub only once mw
    function testSubscription() public {
        uint256[] memory ids = new uint256[](1);
        ids[0] = bobProfileId;
        bytes[] memory data = new bytes[](1);

        uint256 nonce = vm.getNonce(address(profile));
        address subscribeProxy = LibDeploy._calcContractAddress(
            address(profile),
            nonce
        );
        // alice subscribes to bob
        vm.expectEmit(true, true, false, true);
        emit DeploySubscribeNFT(ids[0], subscribeProxy);
        vm.expectEmit(true, false, false, true);
        emit Subscribe(alice, ids, data, data);
        vm.prank(alice);
        uint256 nftid = profile.subscribe(ids, data, data)[0];

        // check bob sub nft supply
        address bobSubNFT = profile.getSubscribeNFT(bobProfileId);
        assertEq(CyberNFTBase(bobSubNFT).totalSupply(), 1);

        // check ownership of first sub nft
        assertEq(ERC721(bobSubNFT).ownerOf(nftid), address(alice));

        // alice subscribes again to bob
        vm.expectEmit(true, false, false, true);
        emit Subscribe(alice, ids, data, data);
        vm.prank(alice);
        nftid = profile.subscribe(ids, data, data)[0];

        // check bob sub nft supply
        assertEq(CyberNFTBase(bobSubNFT).totalSupply(), 2);

        // check ownership of second sub nft
        assertEq(ERC721(bobSubNFT).ownerOf(nftid), address(alice));
    }
}
