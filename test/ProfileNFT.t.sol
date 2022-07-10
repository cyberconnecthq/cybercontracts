// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "../src/core/ProfileNFT.sol";
import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/libraries/Constants.sol";
import "../src/libraries/DataTypes.sol";
import { RolesAuthority } from "../src/dependencies/solmate/RolesAuthority.sol";
import { Authority } from "../src/dependencies/solmate/Auth.sol";
import { SubscribeNFT } from "../src/core/SubscribeNFT.sol";
import { CyberNFTBase } from "../src/base/CyberNFTBase.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { LibString } from "../src/libraries/LibString.sol";
import { ProfileNFTDescriptor } from "../src/periphery/ProfileNFTDescriptor.sol";
import { MockProfileBypassSig } from "./utils/MockProfileBypassSig.sol";
import { LibDeploy } from "../script/libraries/LibDeploy.sol";
import { Roles } from "../src/core/Roles.sol";
import { Base64 } from "../src/dependencies/openzeppelin/Base64.sol";

contract ProfileNFTTest is Test {
    MockProfileBypassSig internal token;
    ProfileNFTDescriptor internal descriptor;
    RolesAuthority internal rolesAuthority;
    address constant alice = address(0xA11CE);
    address constant bob = address(0xA12CE);
    address constant minter = address(0xB0B);
    string constant imageUri = "https://example.com/image.png";
    address constant subscribeMw = address(0xD);
    address constant gov = address(0x8888);
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
        MockProfileBypassSig tokenImpl = new MockProfileBypassSig();
        uint256 nonce = vm.getNonce(address(this));
        address profileAddr = LibDeploy._calcContractAddress(
            address(this),
            nonce + 2
        );
        rolesAuthority = new Roles(address(this), profileAddr);
        descriptor = new ProfileNFTDescriptor(profileAddr);
        bytes memory data = abi.encodeWithSelector(
            ProfileNFT.initialize.selector,
            address(0),
            "TestProfile",
            "TP",
            address(descriptor),
            rolesAuthority
        );
        ERC1967Proxy profileProxy = new ERC1967Proxy(address(tokenImpl), data);
        token = MockProfileBypassSig(address(profileProxy));
        rolesAuthority.setUserRole(
            address(gov),
            Constants._PROFILE_GOV_ROLE,
            true
        );
    }

    function testBasic() public {
        assertEq(token.name(), "TestProfile");
        assertEq(token.symbol(), "TP");
        assertEq(token.paused(), true);
        assertEq(token.subscribeNFTBeacon(), address(0));
        assertEq(token.essenceNFTBeacon(), address(0));
    }

    function testCannotGetTokenURIOfUnmintted() public {
        vm.expectRevert("NOT_MINTED");
        token.tokenURI(0);
    }

    // TODO: add this back or maybe test this in subscribe nft test / integration test
    // function testTokenURISubscriber() public {
    // }

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

    function testCannotCreateProfileLongerThanMaxHandleLength() public {
        vm.expectRevert("HANDLE_INVALID_LENGTH");
        token.createProfile(
            DataTypes.CreateProfileParams(
                alice,
                "aliceandbobisareallylongname",
                "https://example.com/alice.jpg",
                "metadata"
            )
        );
    }

    function testCannotCreateProfileWithAnInvalidCharacter() public {
        vm.expectRevert("HANDLE_INVALID_CHARACTER");
        token.createProfile(
            DataTypes.CreateProfileParams(
                alice,
                "alice&bob",
                imageUri,
                "metadata"
            )
        );
    }

    function testCannotCreateProfileWith0LenthHandle() public {
        vm.expectRevert("HANDLE_INVALID_LENGTH");
        token.createProfile(
            DataTypes.CreateProfileParams(alice, "", imageUri, "metadata")
        );
    }

    function testCannotCreateProfileWithACapitalLetter() public {
        vm.expectRevert("HANDLE_INVALID_CHARACTER");
        token.createProfile(
            DataTypes.CreateProfileParams(alice, "Test", imageUri, "metadata")
        );
    }

    function testCannotCreateProfileWithBlankSpace() public {
        vm.expectRevert("HANDLE_INVALID_CHARACTER");
        token.createProfile(
            DataTypes.CreateProfileParams(alice, " ", imageUri, "metadata")
        );
    }

    // operator
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
        vm.prank(gov);
        token.setProfileNFTDescriptor(address(descriptor));
        assertEq(token.getProfileNFTDescriptor(), address(descriptor));
    }

    // avatar
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
        // creates 2 profiles, bob's profile is automatically set as default
        uint256 profileIdAlice = token.createProfile(createProfileDataAlice);
        uint256 profileIdAlice2 = token.createProfile(createProfileDataBob);
        // get the default profile id
        uint256 primaryIdAlice = token.getPrimaryProfile(alice);
        assertEq(primaryIdAlice, profileIdAlice);
        // set another primary profile id
        token.setPrimaryProfile(profileIdAlice2);
        uint256 primaryIdAlice2 = token.getPrimaryProfile(alice);
        assertEq(profileIdAlice2, primaryIdAlice2);
    }
}

// TODO: test permit
