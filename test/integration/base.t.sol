// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;
import "forge-std/Test.sol";
import { LibDeploy } from "../../script/libraries/LibDeploy.sol";
import { RolesAuthority } from "../../src/dependencies/solmate/RolesAuthority.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IProfileNFTEvents } from "../../src/interfaces/IProfileNFTEvents.sol";
import { ProfileNFT } from "../../src/core/ProfileNFT.sol";
import { TestLibFixture } from "../utils/TestLibFixture.sol";
import { Base64 } from "../../src/dependencies/openzeppelin/Base64.sol";
import { LibString } from "../../src/libraries/LibString.sol";
import { Link3ProfileDescriptor } from "../../src/periphery/Link3ProfileDescriptor.sol";

contract IntegrationBaseTest is Test, IProfileNFTEvents {
    ProfileNFT profileNFT;
    Link3ProfileDescriptor profileDescriptor;
    RolesAuthority authority;
    address boxAddress;
    address profileAddress;
    uint256 bobPk = 1;
    address bob = vm.addr(bobPk);
    uint256 bobProfileId;
    address profileDescriptorAddress;

    function setUp() public {
        LibDeploy.ContractAddresses memory addrs = LibDeploy.deployInTest(vm);
        authority = RolesAuthority(addrs.engineAuthority);
        profileNFT = ProfileNFT(addrs.link3Profile);
        profileDescriptor = Link3ProfileDescriptor(addrs.link3DescriptorProxy);
        // TestLibFixture.auth(authority);
    }

    function testNoop() public {}

    // TODO:
    // function testRegistration() public {
    //     // Register bob profile
    //     vm.expectEmit(true, true, false, true);
    //     emit SetPrimaryProfile(bob, 2); // hardcode profileid
    //     bobProfileId = TestLibFixture.registerBobProfile(profileNFT);

    //     // check bob profile details
    //     string memory handle = profileNFT.getHandleByProfileId(bobProfileId);
    //     string memory avatar = profileNFT.getAvatar(bobProfileId);
    //     string memory metadata = profileNFT.getMetadata(bobProfileId);
    //     address descriptor = profileNFT.getLink3ProfileDescriptor();
    //     string memory animationTemplate = profileDescriptor.animationTemplate();
    //     assertEq(handle, "bob");
    //     assertEq(avatar, "avatar");
    //     assertEq(metadata, "metadata");
    //     assertEq(descriptor, profileDescriptorAddress);
    //     assertEq(animationTemplate, "https://animation.example.com");

    //     // check bob balance
    //     assertEq(profileNFT.balanceOf(bob), 1);

    //     // check bob profile ownership
    //     assertEq(profileNFT.ownerOf(bobProfileId), bob);

    //     // TODO check tokenURI
    //     // assertEq(profileNFT.tokenURI(bobProfileId), bobUri);

    //     assertEq(profileNFT.getPrimaryProfile(bob), bobProfileId);
    //     assertEq(profileNFT.getPrimaryProfile(bob), bobProfileId);

    //     // register second time will not set primary profile
    //     uint256 secondId = TestLibFixture.registerBobProfile(
    //         profileNFT,
    //         1,
    //         "handle2"
    //     );
    //     assertEq(secondId, 3);

    //     // primary profile is still 2
    //     assertEq(profileNFT.getPrimaryProfile(bob), 2);
    //     assertEq(profileNFT.getPrimaryProfile(bob), 2);
    // }
}
