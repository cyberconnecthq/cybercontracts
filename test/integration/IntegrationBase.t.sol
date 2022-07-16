// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;
import { LibDeploy } from "../../script/libraries/LibDeploy.sol";
import { RolesAuthority } from "../../src/dependencies/solmate/RolesAuthority.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IProfileNFTEvents } from "../../src/interfaces/IProfileNFTEvents.sol";
import { ProfileNFT } from "../../src/core/ProfileNFT.sol";
import { TestLibFixture } from "../utils/TestLibFixture.sol";
import { Base64 } from "../../src/dependencies/openzeppelin/Base64.sol";
import { LibString } from "../../src/libraries/LibString.sol";
import { Link3ProfileDescriptor } from "../../src/periphery/Link3ProfileDescriptor.sol";
import { PermissionedFeeCreationMw } from "../../src/middlewares/profile/PermissionedFeeCreationMw.sol";
import { TestIntegrationBase } from "../utils/TestIntegrationBase.sol";

contract IntegrationBaseTest is TestIntegrationBase, IProfileNFTEvents {
    function setUp() public {
        _setUp();
    }

    function testRegistrationTwice() public {
        assertEq(profileMw.getSigner(address(profile)), link3Signer);
        string memory handle = "bob";
        address to = bob;
        // Register bob profile
        vm.expectEmit(true, true, false, true);
        emit SetPrimaryProfile(to, 2); // hardcode profileid
        uint256 bobProfileId = TestLibFixture.registerProfile(
            vm,
            profile,
            profileMw,
            handle,
            to,
            link3SignerPk
        );

        // check bob profile details
        string memory gotHandle = profile.getHandleByProfileId(bobProfileId);
        string memory avatar = profile.getAvatar(bobProfileId);
        string memory metadata = profile.getMetadata(bobProfileId);
        address descriptor = profile.getNFTDescriptor();
        assertEq(gotHandle, handle);
        assertEq(avatar, "avatar");
        assertEq(metadata, "metadata");
        assertEq(descriptor, address(0));

        // check bob balance
        assertEq(profile.balanceOf(to), 1);

        // check bob profile ownership
        assertEq(profile.ownerOf(bobProfileId), to);

        // check tokenURI should revert before setting descriptor
        vm.expectRevert("NFT_DESCRIPTOR_NOT_SET");
        profile.tokenURI(bobProfileId);

        assertEq(profile.getPrimaryProfile(to), bobProfileId);
        assertEq(profile.getPrimaryProfile(to), bobProfileId);

        // register second time will not set primary profile
        uint256 secondId = TestLibFixture.registerProfile(
            vm,
            profile,
            profileMw,
            "handle2",
            to,
            link3SignerPk
        );
        assertEq(secondId, 3);

        // primary profile is still 2
        assertEq(profile.getPrimaryProfile(to), 2);
    }
}
