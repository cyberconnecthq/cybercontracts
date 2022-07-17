// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Base64 } from "../src/dependencies/openzeppelin/Base64.sol";

import { LibString } from "../src/libraries/LibString.sol";
import { Constants } from "../src/libraries/Constants.sol";
import { DataTypes } from "../src/libraries/DataTypes.sol";

import { SubscribeNFT } from "../src/core/SubscribeNFT.sol";
import { ProfileNFT } from "../src/core/ProfileNFT.sol";
import { CyberNFTBase } from "../src/base/CyberNFTBase.sol";
import { MockProfile } from "./utils/MockProfile.sol";
import { TestDeployer } from "./utils/TestDeployer.sol";
import { TestLib712 } from "./utils/TestLib712.sol";

contract ProfileNFTTest is Test, TestDeployer {
    MockProfile internal token;

    uint256 constant alicePk = 100;
    address constant bob = address(0xA12CE);
    address constant gov = address(0x8888);
    address alice = vm.addr(alicePk);
    uint256 validDeadline;

    DataTypes.CreateProfileParams internal createProfileDataAlice =
        DataTypes.CreateProfileParams(
            alice,
            "alice",
            "https://example.com/alice.jpg",
            "metadata"
        );

    DataTypes.CreateProfileParams internal createProfileDataBob =
        DataTypes.CreateProfileParams(
            alice,
            "bob",
            "https://example.com/bob.jpg",
            "metadata"
        );
    string bobMetadata =
        string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    '{"name":"@bob","description":"CyberConnect profile for @bob","image":"img_template?handle=bob","animation_url":"ani_template?handle=bob","attributes":[{"trait_type":"id","value":"1"},{"trait_type":"length","value":"5"},{"trait_type":"subscribers","value":"0"},{"trait_type":"handle","value":"@bob"}]}'
                )
            )
        );

    function setUp() public {
        bytes memory data = abi.encodeWithSelector(
            ProfileNFT.initialize.selector,
            gov,
            "TestProfile",
            "TP",
            address(0)
        );
        address tokenImpl = deployMockProfile(
            address(0xdead),
            address(0xdead),
            address(0xdead)
        );
        ERC1967Proxy profileProxy = new ERC1967Proxy(address(tokenImpl), data);
        token = MockProfile(address(profileProxy));
        validDeadline = block.timestamp + 60 * 60;
    }

    function testBasic() public {
        assertEq(token.name(), "TestProfile");
        assertEq(token.symbol(), "TP");
        assertEq(token.paused(), true);
        assertEq(token.SUBSCRIBE_BEACON(), address(0xdead));
        assertEq(token.ESSENCE_BEACON(), address(0xdead));
    }

    function testCannotGetTokenURIOfUnmintted() public {
        vm.expectRevert("NOT_MINTED");
        token.tokenURI(0);
    }

    function testGetHandleByProfileId() public {
        token.createProfile(createProfileDataAlice);
        assertEq(token.getHandleByProfileId(1), "alice");
    }

    function testGetProfileIdByHandle() public {
        token.createProfile(createProfileDataAlice);
        assertEq(token.getProfileIdByHandle("alice"), 1);
    }

    function testCannotCreateProfileWithHandleTaken() public {
        token.createProfile(createProfileDataAlice);
        vm.expectRevert("HANDLE_TAKEN");
        token.createProfile(createProfileDataAlice);
    }

    function testGetOperatorApproval() public {
        uint256 id = token.createProfile(createProfileDataAlice);
        assertEq(token.getOperatorApproval(id, address(0)), false);
    }

    function testCannotGetOperatorApprovalForNonexistentProfile() public {
        vm.expectRevert("NOT_MINTED");
        token.getOperatorApproval(0, address(0));
    }

    function testCannotSetOperatorToZeroAddress() public {
        uint256 id = token.createProfile(createProfileDataAlice);
        vm.prank(alice);
        vm.expectRevert("ZERO_ADDRESS");
        token.setOperatorApproval(id, address(0), true);
    }

    function testCannotSetMetadataTooLong() public {
        uint256 id = token.createProfile(createProfileDataAlice);

        bytes memory longMetadata = new bytes(Constants._MAX_URI_LENGTH + 1);
        vm.prank(alice);

        vm.expectRevert("METADATA_INVALID_LENGTH");
        token.setMetadata(id, string(longMetadata));
    }

    function testCannotGetMetadataForNonexistentProfile() public {
        vm.expectRevert("NOT_MINTED");
        token.getMetadata(0);
    }

    function testSetDescriptorAsGov() public {
        address descriptor = address(0x666);
        vm.prank(gov);

        token.setNFTDescriptor(address(descriptor));
        assertEq(token.getNFTDescriptor(), address(descriptor));
    }

    function testSetAvatarAsOwner() public {
        uint256 id = token.createProfile(createProfileDataAlice);
        assertEq(token.getAvatar(id), "https://example.com/alice.jpg");
        vm.prank(alice);
        token.setAvatar(id, "avatar");
        assertEq(token.getAvatar(id), "avatar");
    }

    function testCannotGetAvatarForNonexistentProfile() public {
        vm.expectRevert("NOT_MINTED");
        token.getAvatar(0);
    }

    function testCannotSetAvatarTooLong() public {
        uint256 id = token.createProfile(createProfileDataAlice);

        bytes memory longAvatar = new bytes(Constants._MAX_URI_LENGTH + 1);

        vm.expectRevert("AVATAR_INVALID_LENGTH");
        vm.prank(alice);
        token.setAvatar(id, string(longAvatar));
    }

    function testCannotPauseWhenAlreadyPaused() public {
        vm.prank(gov);
        vm.expectRevert("Pausable: paused");
        token.pause(true);
    }

    function testCannotUnpauseWhenAlreadyUnpaused() public {
        vm.startPrank(gov);
        token.pause(false);
        vm.expectRevert("Pausable: not paused");
        token.pause(false);
    }

    function testPause() public {
        vm.startPrank(gov);
        token.pause(false);
        assertEq(token.paused(), false);
        token.pause(true);
        assertEq(token.paused(), true);
    }

    function testUnpause() public {
        vm.startPrank(gov);
        assertEq(token.paused(), true);
        token.pause(false);
        assertEq(token.paused(), false);
    }

    function testCannotSetProfileIdForNonexistentProfile() public {
        vm.expectRevert("NOT_MINTED");
        token.setPrimaryProfile(0);
    }

    function testReturnProfileId() public {
        vm.startPrank(alice);

        uint256 profileIdAlice = token.createProfile(createProfileDataAlice);
        uint256 profileIdAlice2 = token.createProfile(createProfileDataBob);

        uint256 primaryIdAlice = token.getPrimaryProfile(alice);
        assertEq(primaryIdAlice, profileIdAlice);

        token.setPrimaryProfile(profileIdAlice2);
        uint256 primaryIdAlice2 = token.getPrimaryProfile(alice);
        assertEq(profileIdAlice2, primaryIdAlice2);
    }

    function testCannotTransferWhenPaused() public {
        uint256 id = token.createProfile(createProfileDataAlice);
        vm.prank(alice);

        vm.expectRevert("Pausable: paused");
        token.transferFrom(alice, bob, id);
        vm.expectRevert("Pausable: paused");
        token.safeTransferFrom(alice, bob, id);
        vm.expectRevert("Pausable: paused");
        token.safeTransferFrom(alice, bob, id, "");
    }

    function testTransferWhenUnpaused() public {
        uint256 id = token.createProfile(createProfileDataAlice);
        vm.prank(gov);
        token.pause(false);
        assertEq(token.paused(), false);

        vm.prank(alice);
        token.transferFrom(alice, bob, id);
        assertEq(token.ownerOf(id), bob);
    }
}
