// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";
import { BeaconProxy } from "openzeppelin-contracts/contracts/proxy/beacon/BeaconProxy.sol";

import { IProfileNFT } from "../src/interfaces/IProfileNFT.sol";

import { Constants } from "../src/libraries/Constants.sol";
import { DataTypes } from "../src/libraries/DataTypes.sol";

import { MockProfile } from "./utils/MockProfile.sol";
import { TestLib712 } from "./utils/TestLib712.sol";
import { TestDeployer } from "./utils/TestDeployer.sol";
import { UpgradeableBeacon } from "../src/upgradeability/UpgradeableBeacon.sol";
import { SubscribeNFT } from "../src/core/SubscribeNFT.sol";

contract SubscribeNFTTest is Test, TestDeployer {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed id
    );
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
        profile = new MockProfile();
        setProfile(address(profile));
        impl = new SubscribeNFT();
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
        assertEq(c.name(), name);
        assertEq(c.symbol(), symbol);
    }

    function testTokenURI() public {
        vm.prank(address(profile));
        assertEq(c.mint(alice), 1);
        string memory tokenUri = "https://subscriber.1890.com";
        vm.mockCall(
            address(profile),
            abi.encodeWithSelector(
                IProfileNFT.getSubscribeNFTTokenURI.selector,
                profileId
            ),
            abi.encode(tokenUri)
        );
        assertEq(c.tokenURI(1), tokenUri);
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

    function testPermit() public {
        vm.startPrank(address(profile));
        uint256 bobPk = 11111;
        address bobAddr = vm.addr(bobPk);
        uint256 tokenId = c.mint(bobAddr);
        assertEq(c.getApproved(tokenId), address(0));
        vm.warp(50);
        uint256 deadline = 100;
        bytes32 data = keccak256(
            abi.encode(
                Constants._PERMIT_TYPEHASH,
                alice,
                tokenId,
                c.nonces(bobAddr),
                deadline
            )
        );
        bytes32 digest = TestLib712.hashTypedDataV4(
            address(c),
            data,
            name,
            "1"
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(bobPk, digest);
        vm.expectEmit(true, true, true, true);
        emit Approval(bobAddr, alice, tokenId);
        c.permit(alice, tokenId, DataTypes.EIP712Signature(v, r, s, deadline));
        assertEq(c.getApproved(tokenId), alice);
    }
}
