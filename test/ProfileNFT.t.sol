pragma solidity 0.8.14;

import "../src/ProfileNFT.sol";
import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/libraries/Constants.sol";
import "../src/libraries/DataTypes.sol";

contract ProfileNFTTest is Test {
    ProfileNFT internal token;
    address constant alice = address(0xA11CE);
    DataTypes.CreateProfileData internal createProfileData =
        DataTypes.CreateProfileData(
            alice,
            address(0),
            "Alice",
            "https://example.com/alice.jpg"
        );
    string aliceMetadata =
        string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    '{"name":"@Alice","description":"@Alice - CyberConnect profile","attributes":[{"trait_type":"id","value":"#1"},{"trait_type":"owner","value":"0xb4c79dab8f259c7aee6e5b2aa729821864227e84"},{"trait_type":"handle","value":"@Alice"}]}'
                )
            )
        );

    function setUp() public {
        token = new ProfileNFT("TestProfile", "TP", address(this));
        token.setRoleCapability(
            Constants.MINTER_ROLE,
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
        assertEq(address(token.authority()), address(token));
        token.createProfile(createProfileData);
    }

    function testCannotCreateProfileAsNonMinter() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(address(0));
        token.createProfile(createProfileData);
    }

    function testCreateProfileAsMinter() public {
        token.setMinterRole(alice, true);
        vm.prank(alice);
        token.createProfile(createProfileData);
    }

    function testCreateProfile() public {
        assertEq(token.totalSupply(), 0);
        token.createProfile(createProfileData);
        assertEq(token.totalSupply(), 1);
        assertEq(token.balanceOf(alice), 1);
    }

    function testCannotGetTokenURIOfUnmintted() public {
        vm.expectRevert("ERC721: invalid token ID");
        token.tokenURI(0);
    }

    function testTokenURI() public {
        token.createProfile(createProfileData);
        assertEq(token.tokenURI(1), aliceMetadata);
    }

    function testGetHandle() public {
        token.createProfile(createProfileData);
        assertEq(token.getHandle(1), "Alice");
    }
}
