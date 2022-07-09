// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;
import "forge-std/Test.sol";
import { LibDeploy } from "../../script/libraries/LibDeploy.sol";
import { CyberEngine } from "../../src/core/CyberEngine.sol";
import { RolesAuthority } from "../../src/dependencies/solmate/RolesAuthority.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IProfileNFTEvents } from "../../src/interfaces/IProfileNFTEvents.sol";
import { ProfileNFT } from "../../src/core/ProfileNFT.sol";
import { TestLibFixture } from "../utils/TestLibFixture.sol";
import { Base64 } from "../../src/dependencies/openzeppelin/Base64.sol";
import { LibString } from "../../src/libraries/LibString.sol";
import { StaticNFTSVG } from "../../src/libraries/StaticNFTSVG.sol";
import { ProfileNFTDescriptor } from "../../src/periphery/ProfileNFTDescriptor.sol";

contract IntegrationBaseTest is Test, IProfileNFTEvents {
    ProfileNFT profileNFT;
    ProfileNFTDescriptor profileDescriptor;
    RolesAuthority authority;
    address boxAddress;
    address profileAddress;
    uint256 bobPk = 1;
    address bob = vm.addr(bobPk);
    uint256 bobProfileId;
    address profileDescriptorAddress;

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
        profileNFT = ProfileNFT(profileAddress);
        profileDescriptor = ProfileNFTDescriptor(profileDescriptorAddress);
        TestLibFixture.auth(authority);
    }

    function testRegistration() public {
        // Register bob profile
        vm.expectEmit(true, true, false, true);
        emit SetPrimaryProfile(bob, 2); // hardcode profileid
        bobProfileId = TestLibFixture.registerBobProfile(profileNFT);

        // check bob profile details
        string memory handle = profileNFT.getHandleByProfileId(bobProfileId);
        string memory avatar = profileNFT.getAvatar(bobProfileId);
        string memory metadata = profileNFT.getMetadata(bobProfileId);
        address descriptor = profileNFT.getProfileNFTDescriptor();
        string memory animationTemplate = profileDescriptor.animationTemplate();
        assertEq(handle, "bob");
        assertEq(avatar, "avatar");
        assertEq(metadata, "metadata");
        assertEq(descriptor, profileDescriptorAddress);
        assertEq(animationTemplate, "https://animation.example.com");

        // check bob balance
        assertEq(profileNFT.balanceOf(bob), 1);

        // check bob profile ownership
        assertEq(profileNFT.ownerOf(bobProfileId), bob);

        // check bob profile token uri
        string memory bobUri = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{"name":"@',
                        handle,
                        '","description":"CyberConnect profile for @',
                        handle,
                        '","image":"',
                        StaticNFTSVG.draw(handle),
                        '","animation_url":"https://animation.example.com?handle=',
                        handle,
                        '","attributes":[{"trait_type":"id","value":"',
                        LibString.toString(bobProfileId),
                        '"},{"trait_type":"length","value":"',
                        LibString.toString(bytes(handle).length),
                        '"},{"trait_type":"subscribers","value":"0"},{"trait_type":"handle","value":"@',
                        handle,
                        '"}]}'
                    )
                )
            )
        );
        assertEq(profileNFT.tokenURI(bobProfileId), bobUri);
        assertEq(profileNFT.getPrimaryProfile(bob), bobProfileId);
        assertEq(profileNFT.getPrimaryProfile(bob), bobProfileId);

        // register second time will not set primary profile
        uint256 secondId = TestLibFixture.registerBobProfile(
            profileNFT,
            1,
            "handle2"
        );
        assertEq(secondId, 3);

        // primary profile is still 2
        assertEq(profileNFT.getPrimaryProfile(bob), 2);
        assertEq(profileNFT.getPrimaryProfile(bob), 2);
    }
}
