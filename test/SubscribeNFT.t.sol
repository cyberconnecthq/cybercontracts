// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;
import "forge-std/Test.sol";
import { IProfileNFT } from "../src/interfaces/IProfileNFT.sol";
import { UpgradeableBeacon } from "../src/upgradeability/UpgradeableBeacon.sol";
import { SubscribeNFT } from "../src/core/SubscribeNFT.sol";
import { BeaconProxy } from "openzeppelin-contracts/contracts/proxy/beacon/BeaconProxy.sol";
import { Constants } from "../src/libraries/Constants.sol";
import { Auth, Authority } from "../src/dependencies/solmate/Auth.sol";
import { MockProfile } from "./utils/MockProfile.sol";

contract SubscribeNFTTest is Test {
    UpgradeableBeacon internal beacon;
    SubscribeNFT internal impl;
    BeaconProxy internal proxy;
    MockProfile internal profile;

    SubscribeNFT internal c;

    uint256 internal profileId = 1;
    address constant alice = address(0xA11CE);
    address constant bob = address(0xB0B);

    string constant name = "1890_subscriber";
    string constant symbol = "1890_SUB";

    function setUp() public {
        profile = new MockProfile(address(0), address(0));
        impl = new SubscribeNFT(address(profile));
        beacon = new UpgradeableBeacon(address(impl), address(profile));
        bytes memory functionData = abi.encodeWithSelector(
            SubscribeNFT.initialize.selector,
            profileId,
            name,
            symbol
        );
        proxy = new BeaconProxy(address(beacon), functionData);

        c = SubscribeNFT(address(proxy));
    }

    function testBasic() public {
        vm.prank(address(profile));
        assertEq(c.mint(alice), 1);
        assertEq(c.tokenURI(1), "1");
        assertEq(c.name(), name);
        assertEq(c.symbol(), symbol);
    }

    function testCannotReinitialize() public {
        vm.expectRevert("Contract already initialized");
        c.initialize(2, name, symbol);
    }

    function testCannotMintFromNonProfile() public {
        vm.expectRevert("Only profile could mint");
        c.mint(alice);
    }

    function testTransferIsNotAllowed() public {
        vm.prank(address(profile));
        c.mint(alice);
        vm.expectRevert("Transfer is not allowed");
        c.transferFrom(alice, bob, 1);
        vm.expectRevert("Transfer is not allowed");
        c.safeTransferFrom(alice, bob, 1);
        vm.expectRevert("Transfer is not allowed");
        c.safeTransferFrom(alice, bob, 1, "");
    }

    // should return token ID, should increment everytime we call
    function testReturnTokenId() public {
        vm.startPrank(address(profile));
        assertEq(c.mint(alice), 1);
        assertEq(c.mint(alice), 2);
        assertEq(c.mint(alice), 3);
    }

    // TODO: fix permit test
    function testPermit() public {
        // vm.startPrank(address(profile));
        // uint256 bobPk = 11111;
        // address bobAddr = vm.addr(bobPk);
        // uint256 profileId = c.mint(bobAddr);
        //  vm.warp(50);
        // uint256 deadline = 100;
        // bytes32 data = keccak256(
        //     abi.encode(Constants._PERMIT_TYPEHASH, alice, 1, 0, deadline)
        // );
        // bytes32 digest = TestLib712.hashTypedDataV4(
        //     address(token),
        //     data,
        //     "TestNFT",
        //     "1"
        // );
        // profile.permit(spender, tokenId, sig);
    }
}
