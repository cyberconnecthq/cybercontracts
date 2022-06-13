pragma solidity 0.8.14;

import "../src/ProfileNFT.sol";
import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/libraries/Constants.sol";
import "../src/libraries/DataTypes.sol";
import "solmate/auth/authorities/RolesAuthority.sol";
import {Authority} from "solmate/auth/Auth.sol";

contract ProfileNFTTest is Test {
    ProfileNFT internal token;
    RolesAuthority internal rolesAuthority;
    address constant alice = address(0xA11CE);
    string constant imageUri = "https://example.com/image.png";
    DataTypes.ProfileStruct internal createProfileData =
        DataTypes.ProfileStruct(
            "alice",
            "https://example.com/alice.jpg"
        );
    string aliceMetadata =
        string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    '{"name":"@alice","description":"@alice - CyberConnect profile","attributes":[{"trait_type":"id","value":"#1"},{"trait_type":"owner","value":"0xb4c79dab8f259c7aee6e5b2aa729821864227e84"},{"trait_type":"handle","value":"@alice"}]}'
                )
            )
        );

    function setUp() public {
        rolesAuthority = new RolesAuthority(address(this), Authority(address(0)));
        token = new ProfileNFT("TestProfile", "TP", address(this), rolesAuthority);
        rolesAuthority.setRoleCapability(
            Constants.PROFILE_MINTER_ROLE,
            address(token),
            Constants.CREATE_PROFILE_ID,
            true
        );
    }

    function testBasic() public {
        assertEq(token.name(), "TestProfile");
        assertEq(token.symbol(), "TP");
    }

    function testAuth() public {
        assertEq(address(token.authority()), address(rolesAuthority));
        token.createProfile(alice, createProfileData);
    }

    function testCannotCreateProfileAsNonMinter() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(address(0));
        token.createProfile(alice, createProfileData);
    }

    function testCreateProfileAsMinter() public {
        rolesAuthority.setUserRole(alice, Constants.PROFILE_MINTER_ROLE, true);
        vm.prank(alice);
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

    function testGetHandle() public {
        token.createProfile(alice, createProfileData);
        assertEq(token.getHandle(1), "alice");
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
        token.createProfile(alice, DataTypes.ProfileStruct(
            "aliceandbobisareallylongname",
            "https://example.com/alice.jpg"
        ));
    }

    function testCannotCreateProfileWithAnInvalidCharacter() public {
        vm.expectRevert("Handle contains invalid character");
        token.createProfile(alice, DataTypes.ProfileStruct(
            "alice&bob",
            imageUri
        ));
    }

    function testCannotCreateProfileWith0LenthHandle() public {
        vm.expectRevert("Handle has invalid length");
        token.createProfile(alice, DataTypes.ProfileStruct(
            "",
            imageUri
        ));
    }

    function testConnotCreateProfileWithACapitalLetter() public {
        vm.expectRevert("Handle contains invalid character");
        token.createProfile(alice, DataTypes.ProfileStruct("Test", imageUri));
    }
}
