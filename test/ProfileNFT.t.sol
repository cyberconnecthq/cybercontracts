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
    RolesAuthority internal rolesAuthority;
    address constant alice = address(0xA11CE);
    address constant minter = address(0xB0B);
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
        rolesAuthority = new RolesAuthority(
            address(this),
            Authority(address(0))
        );
        token = new ProfileNFT();
        token.initialize("TestProfile", "TP", address(0), rolesAuthority);
        rolesAuthority.setRoleCapability(
            Constants._NFT_MINTER_ROLE,
            address(token),
            Constants._PROFILE_CREATE_PROFILE_ID,
            true
        );
        rolesAuthority.setUserRole(
            address(this),
            Constants._NFT_MINTER_ROLE,
            true
        );
    }

    function testBasic() public {
        assertEq(token.name(), "TestProfile");
        assertEq(token.symbol(), "TP");
    }

    function testAuth() public {
        assertEq(address(token.authority()), address(rolesAuthority));
    }

    function testCreateProfileAsOwner() public {
        token.createProfile(alice, createProfileData);
    }

    function testCannotCreateProfileAsNonMinter() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(address(0xDEAD));
        token.createProfile(alice, createProfileData);
    }

    function testCreateProfileAsMinter() public {
        rolesAuthority.setUserRole(minter, Constants._NFT_MINTER_ROLE, true);
        vm.prank(minter);
        token.createProfile(alice, createProfileData);
    }

    function testCreateProfile() public {
        assertEq(token.totalSupply(), 0);
        token.createProfile(alice, createProfileData);
        assertEq(token.totalSupply(), 1);
        assertEq(token.balanceOf(alice), 1);
    }

    function testCannotGetTokenURIOfUnmintted() public {
        vm.expectRevert("ERC721: invalid token ID");
        token.tokenURI(0);
    }

    function testTokenURI() public {
        token.createProfile(alice, createProfileData);
        assertEq(token.tokenURI(1), aliceMetadata);
    }

    function test() public {
        token.createProfile(alice, createProfileData);
        assertEq(token.getHandleByProfileId(1), "alice");
    }

    function testGetProfileIdByHandle() public {
        token.createProfile(alice, createProfileData);
        assertEq(token.getProfileIdByHandle("alice"), 1);
    }

    function testCannotCreateProfileWithHandleTaken() public {
        token.createProfile(alice, createProfileData);
        vm.expectRevert("Handle taken");
        token.createProfile(alice, createProfileData);
    }

    function testCannotCreateProfileLongerThanMaxHandleLength() public {
        vm.expectRevert("Handle has invalid length");
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
        token.createProfile(
            alice,
            DataTypes.ProfileStruct("alice&bob", imageUri, address(0))
        );
    }

    function testCannotCreateProfileWith0LenthHandle() public {
        vm.expectRevert("Handle has invalid length");
        token.createProfile(
            alice,
            DataTypes.ProfileStruct("", imageUri, address(0))
        );
    }

    function testCannotCreateProfileWithACapitalLetter() public {
        vm.expectRevert("Handle contains invalid character");
        token.createProfile(
            alice,
            DataTypes.ProfileStruct("Test", imageUri, address(0))
        );
    }

    function testCannotCreateProfileWithBlankSpace() public {
        vm.expectRevert("Handle contains invalid character");
        token.createProfile(
            alice,
            DataTypes.ProfileStruct(" ", imageUri, address(0))
        );
    }
}
