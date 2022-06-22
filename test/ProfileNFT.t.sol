// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "../src/ProfileNFT.sol";
import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/libraries/Constants.sol";
import "../src/libraries/DataTypes.sol";
import { RolesAuthority } from "../src/base/RolesAuthority.sol";
import { Authority } from "../src/base/Auth.sol";

contract ProfileNFTTest is Test {
    ProfileNFT internal token;
    address constant alice = address(0xA11CE);
    address constant minter = address(0xB0B);
    address constant engine = address(0xE);
    string constant imageUri = "https://example.com/image.png";
    DataTypes.ProfileStruct internal createProfileData =
        DataTypes.ProfileStruct(
            "alice",
            "https://example.com/alice.jpg",
            address(0)
        );
    string aliceMetadata =
        string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    '{"name":"@alice","description":"@alice - CyberConnect profile","attributes":[{"trait_type":"id","value":"#1"},{"trait_type":"owner","value":"0x00000000000000000000000000000000000a11ce"},{"trait_type":"handle","value":"@alice"}]}'
                )
            )
        );

    function setUp() public {
        token = new ProfileNFT(engine);
        token.initialize("TestProfile", "TP");
    }

    function testBasic() public {
        assertEq(token.name(), "TestProfile");
        assertEq(token.symbol(), "TP");
    }

    function testAuth() public {
        assertEq(address(token.ENGINE()), engine);
    }

    function testCannotCreateProfileAsNonEngine() public {
        vm.expectRevert("Only Engine could create profile");
        vm.prank(address(0xDEAD));
        token.createProfile(alice, createProfileData);
    }

    function testCreateProfileAsEngine() public {
        vm.prank(engine);
        assertEq(token.createProfile(alice, createProfileData), 1);
    }

    function testCreateProfile() public {
        assertEq(token.totalSupply(), 0);
        vm.prank(engine);
        token.createProfile(alice, createProfileData);
        assertEq(token.totalSupply(), 1);
        assertEq(token.balanceOf(alice), 1);
    }

    function testCannotGetTokenURIOfUnmintted() public {
        vm.expectRevert("ERC721: invalid token ID");
        token.tokenURI(0);
    }

    function testTokenURI() public {
        vm.prank(engine);
        token.createProfile(alice, createProfileData);
        assertEq(token.tokenURI(1), aliceMetadata);
    }

    function test() public {
        vm.prank(engine);
        token.createProfile(alice, createProfileData);
        assertEq(token.getHandleByProfileId(1), "alice");
    }

    function testGetProfileIdByHandle() public {
        vm.prank(engine);
        token.createProfile(alice, createProfileData);
        assertEq(token.getProfileIdByHandle("alice"), 1);
    }

    function testCannotCreateProfileWithHandleTaken() public {
        vm.prank(engine);
        token.createProfile(alice, createProfileData);
        vm.expectRevert("Handle taken");
        vm.prank(engine);
        token.createProfile(alice, createProfileData);
    }

    function testCannotCreateProfileLongerThanMaxHandleLength() public {
        vm.expectRevert("Handle has invalid length");
        vm.prank(engine);
        token.createProfile(
            alice,
            DataTypes.ProfileStruct(
                "aliceandbobisareallylongname",
                "https://example.com/alice.jpg",
                address(0)
            )
        );
    }

    function testCannotCreateProfileWithAnInvalidCharacter() public {
        vm.expectRevert("Handle contains invalid character");
        vm.prank(engine);
        token.createProfile(
            alice,
            DataTypes.ProfileStruct("alice&bob", imageUri, address(0))
        );
    }

    function testCannotCreateProfileWith0LenthHandle() public {
        vm.expectRevert("Handle has invalid length");
        vm.prank(engine);
        token.createProfile(
            alice,
            DataTypes.ProfileStruct("", imageUri, address(0))
        );
    }

    function testCannotCreateProfileWithACapitalLetter() public {
        vm.expectRevert("Handle contains invalid character");
        vm.prank(engine);
        token.createProfile(
            alice,
            DataTypes.ProfileStruct("Test", imageUri, address(0))
        );
    }

    function testCannotCreateProfileWithBlankSpace() public {
        vm.expectRevert("Handle contains invalid character");
        vm.prank(engine);
        token.createProfile(
            alice,
            DataTypes.ProfileStruct(" ", imageUri, address(0))
        );
    }

    function testCannotSetSubscribeNFTAddress() public {
        vm.expectRevert("Only Engine could set SubscribeNFT address");
        token.setSubscribeNFTAddress(0, address(0));
    }

    function testSetSubscribeNFTAddress() public {
        vm.prank(engine);
        token.setSubscribeNFTAddress(0, address(0));
    }
}
