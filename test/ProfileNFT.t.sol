// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "../src/ProfileNFT.sol";
import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/libraries/Constants.sol";
import "../src/libraries/DataTypes.sol";
import { RolesAuthority } from "../src/dependencies/solmate/RolesAuthority.sol";
import { Authority } from "../src/dependencies/solmate/Auth.sol";
import { SubscribeNFT } from "../src/SubscribeNFT.sol";
import { CyberNFTBase } from "../src/base/CyberNFTBase.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract ProfileNFTTest is Test {
    ProfileNFT internal token;
    address constant alice = address(0xA11CE);
    address constant minter = address(0xB0B);
    address constant engine = address(0xE);
    string constant imageUri = "https://example.com/image.png";
    address constant subscribeMw = address(0xD);
    DataTypes.CreateProfileParams internal createProfileData =
        DataTypes.CreateProfileParams(
            alice,
            "alice",
            "https://example.com/alice.jpg",
            "metadata"
        );
    string aliceMetadata =
        string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    '{"name":"@alice","description":"CyberConnect profile for @alice","image":"img_template?handle=alice","animation_url":"ani_template?handle=alice","attributes":[{"trait_type":"id","value":"1"},{"trait_type":"length","value":"5"},{"trait_type":"subscribers","value":"0"},{"trait_type":"handle","value":"@alice"}]}'
                )
            )
        );

    function setUp() public {
        ProfileNFT tokenImpl = new ProfileNFT(engine);
        bytes memory data = abi.encodeWithSelector(
            ProfileNFT.initialize.selector,
            "TestProfile",
            "TP",
            "ani_template",
            "img_template"
        );
        ERC1967Proxy engineProxy = new ERC1967Proxy(address(tokenImpl), data);
        token = ProfileNFT(address(engineProxy));
    }

    function testBasic() public {
        assertEq(token.name(), "TestProfile");
        assertEq(token.symbol(), "TP");
        assertEq(token.paused(), true);
    }

    function testAuth() public {
        assertEq(address(token.ENGINE()), engine);
    }

    function testCannotCreateProfileAsNonEngine() public {
        vm.expectRevert("Only Engine");
        vm.prank(address(0xDEAD));
        token.createProfile(createProfileData);
    }

    function testCreateProfileAsEngine() public {
        vm.prank(engine);
        assertEq(token.createProfile(createProfileData), 1);
    }

    function testCreateProfile() public {
        assertEq(token.totalSupply(), 0);
        vm.prank(engine);
        token.createProfile(createProfileData);
        assertEq(token.totalSupply(), 1);
        assertEq(token.balanceOf(alice), 1);
        // TODO: subscribe middle ware should eq the correct address
    }

    function testCannotGetTokenURIOfUnmintted() public {
        vm.expectRevert("NOT_MINTED");
        token.tokenURI(0);
    }

    function testTokenURI() public {
        vm.prank(engine);
        token.createProfile(createProfileData);
        vm.mockCall(
            engine,
            abi.encodeWithSelector(CyberEngine.getSubscribeNFT.selector, 1),
            abi.encode(address(0))
        );
        assertEq(token.tokenURI(1), aliceMetadata);
    }

    function testTokenURISubscriber() public {
        vm.prank(engine);
        token.createProfile(createProfileData);

        address subscribeNFT = address(0x1111);
        vm.mockCall(
            engine,
            abi.encodeWithSelector(CyberEngine.getSubscribeNFT.selector, 1),
            abi.encode(subscribeNFT)
        );
        string memory expected = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    '{"name":"@alice","description":"CyberConnect profile for @alice","image":"img_template?handle=alice","animation_url":"ani_template?handle=alice","attributes":[{"trait_type":"id","value":"1"},{"trait_type":"length","value":"5"},{"trait_type":"subscribers","value":"111"},{"trait_type":"handle","value":"@alice"}]}'
                )
            )
        );
        vm.mockCall(
            subscribeNFT,
            abi.encodeWithSelector(CyberNFTBase.totalSupply.selector),
            abi.encode(111)
        );
        assertEq(token.tokenURI(1), expected);
    }

    function test() public {
        vm.prank(engine);
        token.createProfile(createProfileData);
        assertEq(token.getHandleByProfileId(1), "alice");
    }

    function testGetProfileIdByHandle() public {
        vm.prank(engine);
        token.createProfile(createProfileData);
        assertEq(token.getProfileIdByHandle("alice"), 1);
    }

    function testCannotCreateProfileWithHandleTaken() public {
        vm.prank(engine);
        token.createProfile(createProfileData);
        vm.expectRevert("Handle taken");
        vm.prank(engine);
        token.createProfile(createProfileData);
    }

    function testCannotCreateProfileLongerThanMaxHandleLength() public {
        vm.expectRevert("Handle has invalid length");
        vm.prank(engine);
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
        vm.expectRevert("Handle has invalid character");
        vm.prank(engine);
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
        vm.expectRevert("Handle has invalid length");
        vm.prank(engine);
        token.createProfile(
            DataTypes.CreateProfileParams(alice, "", imageUri, "metadata")
        );
    }

    function testCannotCreateProfileWithACapitalLetter() public {
        vm.expectRevert("Handle has invalid character");
        vm.prank(engine);
        token.createProfile(
            DataTypes.CreateProfileParams(alice, "Test", imageUri, "metadata")
        );
    }

    function testCannotCreateProfileWithBlankSpace() public {
        vm.expectRevert("Handle has invalid character");
        vm.prank(engine);
        token.createProfile(
            DataTypes.CreateProfileParams(alice, " ", imageUri, "metadata")
        );
    }

    // operator
    function testGetOperatorApproval() public {
        vm.prank(engine);
        uint256 id = token.createProfile(createProfileData);
        assertEq(token.getOperatorApproval(id, address(0)), false);
    }

    function testCannotGetOperatorApprovalForNonexistentProfile() public {
        vm.expectRevert("NOT_MINTED");
        token.getOperatorApproval(0, address(0));
    }

    function testCannotSetOperatorIfNotEngine() public {
        vm.prank(engine);
        uint256 id = token.createProfile(createProfileData);
        vm.expectRevert("Only Engine");
        token.setOperatorApproval(id, address(0), true);
    }

    function testCannotSetOperatorToZeroAddress() public {
        vm.prank(engine);
        uint256 id = token.createProfile(createProfileData);
        vm.prank(engine);
        vm.expectRevert("Operator address cannot be 0");
        token.setOperatorApproval(id, address(0), true);
    }

    // metadata
    function testSetMetadataAsEngine() public {
        vm.prank(engine);
        uint256 id = token.createProfile(createProfileData);
        assertEq(token.getMetadata(id), "metadata");
        vm.prank(engine);
        token.setMetadata(id, "ipfs");
        assertEq(token.getMetadata(id), "ipfs");
    }

    function testCannotSetMetadataTooLong() public {
        vm.prank(engine);
        uint256 id = token.createProfile(createProfileData);

        bytes memory longMetadata = new bytes(Constants._MAX_URI_LENGTH + 1);
        vm.prank(engine);

        vm.expectRevert("Metadata has invalid length");
        token.setMetadata(id, string(longMetadata));
    }

    function testCannotGetMetadataForNonexistentProfile() public {
        vm.expectRevert("NOT_MINTED");
        token.getMetadata(0);
    }

    function testCannotSetMetadataIfNotEngine() public {
        vm.prank(engine);
        uint256 id = token.createProfile(createProfileData);
        vm.expectRevert("Only Engine");
        token.setMetadata(id, "ipfs");
    }

    // template
    function testCannotSetTemplateIfNotEngine() public {
        vm.expectRevert("Only Engine");
        token.setAnimationTemplate("template");

        vm.expectRevert("Only Engine");
        token.setImageTemplate("template");
    }

    function testSetTemplateAsEngine() public {
        vm.prank(engine);
        token.setAnimationTemplate("ani_template");
        assertEq(token.getAnimationTemplate(), "ani_template");

        vm.prank(engine);
        token.setImageTemplate("img_template");
        assertEq(token.getImageTemplate(), "img_template");
    }

    // avatar
    function testSetAvatarAsEngine() public {
        vm.prank(engine);
        uint256 id = token.createProfile(createProfileData);
        assertEq(token.getAvatar(id), "https://example.com/alice.jpg");
        vm.prank(engine);
        token.setAvatar(id, "avatar");
        assertEq(token.getAvatar(id), "avatar");
    }

    function testCannotGetAvatarForNonexistentProfile() public {
        vm.expectRevert("NOT_MINTED");
        token.getAvatar(0);
    }

    function testCannotSetAvatarIfNotEngine() public {
        vm.prank(engine);
        uint256 id = token.createProfile(createProfileData);
        vm.expectRevert("Only Engine");
        token.setAvatar(id, "ipfs");
    }

    function testCannotSetAvatarTooLong() public {
        vm.prank(engine);
        uint256 id = token.createProfile(createProfileData);

        bytes memory longAvatar = new bytes(Constants._MAX_URI_LENGTH + 1);
        vm.prank(engine);

        vm.expectRevert("Avatar has invalid length");
        token.setAvatar(id, string(longAvatar));
    }

    // set prank as non engine, then try to pause, should be reverted
    function testCannotPauseFromNonEngine() public {
        vm.expectRevert("Only Engine");
        vm.prank(address(0));
        token.pause(true);
    }

    // set prank as engine, then try to pause again, since it was paused already(from initialization), it can't pause again
    function testCannotPauseWhenAlreadyPaused() public {
        vm.prank(engine);
        vm.expectRevert("Pausable: paused");
        token.pause(true);
    }

    // we first unpause, verify, then we unpause, then verify, we can't unpause when already unpaused
    function testCannotUnpauseWhenAlreadyUnpaused() public {
        vm.startPrank(engine);
        token.pause(false);
        vm.expectRevert("Pausable: not paused");
        token.pause(false);
    }

    // we first unpause, verify, then we unpause, then verify
    function testPause() public {
        vm.startPrank(engine);
        token.pause(false);
        assertEq(token.paused(), false);
        token.pause(true);
        assertEq(token.paused(), true);
    }
    // we first verify that the contracy is paused, then unpause, and verify
    function testUnpause() public {
        vm.startPrank(engine);
        assertEq(token.paused(), true);
        token.pause(false);
        assertEq(token.paused(), false);
    }
}
