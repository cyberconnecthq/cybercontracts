// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";

import { UpgradeableBeacon } from "../src/upgradeability/UpgradeableBeacon.sol";
import { BeaconProxy } from "openzeppelin-contracts/contracts/proxy/beacon/BeaconProxy.sol";
import { ProfileNFT } from "../src/core/ProfileNFT.sol";
import { EssenceNFT } from "../src/core/EssenceNFT.sol";
import { Constants } from "../src/libraries/Constants.sol";
import { TestLib712 } from "./utils/TestLib712.sol";
import { DataTypes } from "../src/libraries/DataTypes.sol";

contract EssenceNFTTest is Test {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed id
    );

    UpgradeableBeacon internal beacon;
    EssenceNFT internal impl;
    BeaconProxy internal proxy;
    ProfileNFT internal profile;

    uint256 internal profileId = 18;
    uint256 internal essenceId = 90;
    string internal name = "1890's supporters";
    string internal symbol = "1890 GANG";

    EssenceNFT internal essence;

    address constant alice = address(0xA11CE);
    address constant bob = address(0xB0B);

    function setUp() public {
        profile = new ProfileNFT(address(0), address(0));
        impl = new EssenceNFT(address(profile));
        beacon = new UpgradeableBeacon(address(impl), address(profile));
        bytes memory functionData = abi.encodeWithSelector(
            EssenceNFT.initialize.selector,
            profileId,
            essenceId,
            name,
            symbol
        );
        proxy = new BeaconProxy(address(beacon), functionData);
        essence = EssenceNFT(address(proxy));
    }

    function testBasic() public {
        assertEq(essence.name(), name);
        assertEq(essence.symbol(), symbol);
    }

    function testMint() public {
        vm.prank(address(profile));
        assertEq(essence.mint(alice), 1);
    }

    function testCannotMintAsNonProfile() public {
        vm.expectRevert("ONLY_PROFILE");
        essence.mint(alice);
    }

    function testPermit() public {
        vm.startPrank(address(profile));
        uint256 bobPk = 11111;
        address bobAddr = vm.addr(bobPk);
        uint256 tokenId = essence.mint(bobAddr);
        vm.warp(50);
        uint256 deadline = 100;
        bytes32 data = keccak256(
            abi.encode(
                Constants._PERMIT_TYPEHASH,
                alice,
                tokenId,
                essence.nonces(bobAddr),
                deadline
            )
        );
        bytes32 digest = TestLib712.hashTypedDataV4(
            address(essence),
            data,
            name,
            "1"
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(bobPk, digest);
        vm.expectEmit(true, true, true, true);
        emit Approval(bobAddr, alice, tokenId);
        essence.permit(
            alice,
            tokenId,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
    }

    function testVersion() public {
        assertEq(essence.version(), 1);
    }
}
