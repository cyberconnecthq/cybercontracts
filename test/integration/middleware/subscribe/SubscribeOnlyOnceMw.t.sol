// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;
import "forge-std/Test.sol";
import { LibDeploy } from "../../../../script/libraries/LibDeploy.sol";
import { TestLibFixture } from "../../../utils/TestLibFixture.sol";
import { RolesAuthority } from "../../../../src/dependencies/solmate/RolesAuthority.sol";
import { SubscribeOnlyOnceMw } from "../../../../src/middlewares/subscribe/SubscribeOnlyOnceMw.sol";
import { Constants } from "../../../../src/libraries/Constants.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IProfileNFTEvents } from "../../../../src/interfaces/IProfileNFTEvents.sol";
import { ProfileNFT } from "../../../../src/core/ProfileNFT.sol";

contract SubscribeOnlyOnceMwTest is Test, IProfileNFTEvents {
    SubscribeOnlyOnceMw mw;
    RolesAuthority authority;
    address boxAddress;
    address profileAddress;
    address alice = address(0xA11CE);
    uint256 bobPk = 1;
    address bob = vm.addr(bobPk); // matches TestLibFixture
    uint256 bobProfileId;
    address profileDescriptorAddress;
    ProfileNFT profileNFT;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );

    function setUp() public {
        mw = new SubscribeOnlyOnceMw();
        vm.label(address(mw), "SubscribeMiddleware");
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
        profileNFT = ProfileNFT(address(profileAddress));

        TestLibFixture.auth(authority);
        vm.prank(TestLibFixture._GOV);
        profileNFT.allowSubscribeMw(address(mw), true);
        bobProfileId = TestLibFixture.registerBobProfile(profileNFT);
        // set module
        vm.prank(bob);
        profileNFT.setSubscribeMw(bobProfileId, address(mw), new bytes(0));
    }

    function testSubscribeOnlyOnce() public {
        uint256[] memory ids = new uint256[](1);
        ids[0] = bobProfileId;
        bytes[] memory data = new bytes[](1);

        uint256 nonce = vm.getNonce(address(profileNFT));
        address subscribeProxy = LibDeploy._calcContractAddress(
            address(profileNFT),
            nonce
        );

        vm.expectEmit(true, true, false, true);
        emit DeploySubscribeNFT(bobProfileId, address(subscribeProxy));

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), alice, 1);

        vm.expectEmit(true, false, false, true);
        emit Subscribe(alice, ids, data, data);

        vm.prank(alice);
        profileNFT.subscribe(ids, data, data);

        // Second subscribe will fail
        vm.expectRevert("Already subscribed");
        vm.prank(alice);
        profileNFT.subscribe(ids, data, data);
    }
}
