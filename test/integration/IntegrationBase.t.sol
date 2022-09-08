// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;
import { LibDeploy } from "../../script/libraries/LibDeploy.sol";
import { RolesAuthority } from "../../src/dependencies/solmate/RolesAuthority.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IProfileNFTEvents } from "../../src/interfaces/IProfileNFTEvents.sol";
import { ProfileNFT } from "../../src/core/ProfileNFT.sol";
import { TestLibFixture } from "../utils/TestLibFixture.sol";
import { Base64 } from "openzeppelin-contracts/contracts/utils/Base64.sol";
import { LibString } from "../../src/libraries/LibString.sol";
import { Link3ProfileDescriptor } from "../../src/periphery/Link3ProfileDescriptor.sol";
import { PermissionedFeeCreationMw } from "../../src/middlewares/profile/PermissionedFeeCreationMw.sol";
import { TestIntegrationBase } from "../utils/TestIntegrationBase.sol";

contract IntegrationBaseTest is TestIntegrationBase, IProfileNFTEvents {
    function setUp() public {
        _setUp();
    }

    function testRegistrationTwice() public {
        assertEq(profileMw.getSigner(address(link3Profile)), link3Signer);
        string memory handle = "bob";
        address to = bob;
        // Register bob profile
        vm.expectEmit(true, true, false, true);
        emit SetPrimaryProfile(to, 2); // hardcode profileid
        uint256 bobProfileId = TestLibFixture.registerProfile(
            vm,
            link3Profile,
            profileMw,
            handle,
            to,
            link3SignerPk
        );

        // check bob profile details
        string memory gotHandle = link3Profile.getHandleByProfileId(
            bobProfileId
        );
        string memory avatar = link3Profile.getAvatar(bobProfileId);
        string memory metadata = link3Profile.getMetadata(bobProfileId);
        address descriptor = link3Profile.getNFTDescriptor();
        assertEq(gotHandle, handle);
        assertEq(avatar, "avatar");
        assertEq(metadata, "metadata");

        // check bob balance
        assertEq(link3Profile.balanceOf(to), 1);

        // check bob profile ownership
        assertEq(link3Profile.ownerOf(bobProfileId), to);

        assertEq(link3Profile.getPrimaryProfile(to), bobProfileId);
        assertEq(link3Profile.getPrimaryProfile(to), bobProfileId);

        // register second time will not set primary profile
        uint256 secondId = TestLibFixture.registerProfile(
            vm,
            link3Profile,
            profileMw,
            "handle2",
            to,
            link3SignerPk
        );
        assertEq(secondId, 3);

        // primary profile is still 2
        assertEq(link3Profile.getPrimaryProfile(to), 2);
    }
}
