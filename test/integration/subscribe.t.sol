// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;
import "forge-std/Test.sol";
import { LibDeploy } from "../../script/libraries/LibDeploy.sol";
import { CyberNFTBase } from "../../src/base/CyberNFTBase.sol";
import { CyberEngine } from "../../src/core/CyberEngine.sol";
import { RolesAuthority } from "../../src/dependencies/solmate/RolesAuthority.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { ICyberEngineEvents } from "../../src/interfaces/ICyberEngineEvents.sol";
import { SubscribeNFT } from "../../src/core/SubscribeNFT.sol";
import { LibFixture } from "../../script/libraries/LibFixture.sol";
import { Base64 } from "../../src/dependencies/openzeppelin/Base64.sol";
import { LibString } from "../../src/libraries/LibString.sol";
import { ERC721 } from "../../src/dependencies/solmate/ERC721.sol";

contract SubscribeTest is Test, ICyberEngineEvents {
    CyberEngine engine;
    SubscribeNFT subNFT;
    RolesAuthority authority;
    address boxAddress;
    address profileAddress;
    address alice = address(0xA11CE);
    uint256 bobPk = 1;
    address bob = vm.addr(bobPk);
    uint256 bobProfileId;

    function setUp() public {
        uint256 nonce = vm.getNonce(address(this));
        ERC1967Proxy proxy;
        (proxy, authority, boxAddress, profileAddress) = LibDeploy.deploy(
            address(this),
            nonce,
            ""
        );
        LibFixture.auth(authority);
        engine = CyberEngine(address(proxy));
        bobProfileId = LibFixture.registerBobProfile(engine);
        LibFixture.auth(authority);
    }

    // test sub without sub only once mw
    function testSubscription() public {
        uint256[] memory ids = new uint256[](1);
        ids[0] = bobProfileId;
        bytes[] memory data = new bytes[](1);

        // alice subscribes to bob
        vm.expectEmit(true, false, false, true);
        emit Subscribe(alice, ids, data);
        vm.prank(alice);
        uint256 nftid = engine.subscribe(ids, data)[0];

        // check bob sub nft supply
        address bobSubNFT = engine.getSubscribeNFT(bobProfileId);
        assertEq(CyberNFTBase(bobSubNFT).totalSupply(), 1);

        // check ownership of first sub nft
        assertEq(ERC721(bobSubNFT).ownerOf(nftid), address(alice));

        // alice subscribes again to bob
        vm.expectEmit(true, false, false, true);
        emit Subscribe(alice, ids, data);
        vm.prank(alice);
        nftid = engine.subscribe(ids, data)[0];

        // check bob sub nft supply
        assertEq(CyberNFTBase(bobSubNFT).totalSupply(), 2);

        // check ownership of second sub nft
        assertEq(ERC721(bobSubNFT).ownerOf(nftid), address(alice));
    }
}