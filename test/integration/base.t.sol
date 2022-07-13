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
    ProfileNFT profileNFT;
    Link3ProfileDescriptor profileDescriptor;
    RolesAuthority authority;
    PermissionedFeeCreationMw mw;
    address boxAddress;
    address profileAddress;
    uint256 bobProfileId;

    function setUp() public {
        LibDeploy.ContractAddresses memory addrs = LibDeploy.deployInTest(
            vm,
            link3Signer
        );
        authority = RolesAuthority(addrs.engineAuthority);
        profileNFT = ProfileNFT(addrs.link3Profile);
        profileDescriptor = Link3ProfileDescriptor(addrs.link3DescriptorProxy);
        mw = PermissionedFeeCreationMw(addrs.link3ProfileMw);
    }

    function testNoop() public {}

    function testRegistrationTwice() public {
        assertEq(mw.getSigner(address(profileNFT)), link3Signer);
        string memory handle = "bob";
        address to = address(0xA11CE);
        // Register bob profile
        vm.expectEmit(true, true, false, true);
        emit SetPrimaryProfile(to, 2); // hardcode profileid
        bobProfileId = TestLibFixture.registerBobProfile(
            vm,
            profileNFT,
            mw,
            handle,
            to,
            link3SignerPk
        );

        // check bob profile details
        string memory gotHandle = profileNFT.getHandleByProfileId(bobProfileId);
        string memory avatar = profileNFT.getAvatar(bobProfileId);
        string memory metadata = profileNFT.getMetadata(bobProfileId);
        address descriptor = profileNFT.getNFTDescriptor();
        assertEq(gotHandle, handle);
        assertEq(avatar, "avatar");
        assertEq(metadata, "metadata");
        assertEq(descriptor, address(0));

        // check bob balance
        assertEq(profileNFT.balanceOf(to), 1);

        // check bob profile ownership
        assertEq(profileNFT.ownerOf(bobProfileId), to);

        // TODO check tokenURI
        // assertEq(profileNFT.tokenURI(bobProfileId), bobUri);

        assertEq(profileNFT.getPrimaryProfile(to), bobProfileId);
        assertEq(profileNFT.getPrimaryProfile(to), bobProfileId);

        // register second time will not set primary profile
        uint256 secondId = TestLibFixture.registerBobProfile(
            vm,
            profileNFT,
            mw,
            "handle2",
            to,
            link3SignerPk
        );
        assertEq(secondId, 3);

        // primary profile is still 2
        assertEq(profileNFT.getPrimaryProfile(to), 2);
    }
}
