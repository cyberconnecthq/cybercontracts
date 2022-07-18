// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";
import { BeaconProxy } from "openzeppelin-contracts/contracts/proxy/beacon/BeaconProxy.sol";

import { IProfileNFT } from "../src/interfaces/IProfileNFT.sol";
import { IEssenceNFTEvents } from "../src/interfaces/IEssenceNFTEvents.sol";

import { Constants } from "../src/libraries/Constants.sol";
import { DataTypes } from "../src/libraries/DataTypes.sol";

import { UpgradeableBeacon } from "../src/upgradeability/UpgradeableBeacon.sol";
import { ProfileNFT } from "../src/core/ProfileNFT.sol";
import { EssenceNFT } from "../src/core/EssenceNFT.sol";
import { TestLib712 } from "./utils/TestLib712.sol";
import { TestDeployer } from "./utils/TestDeployer.sol";

contract EssenceNFTTest is Test, TestDeployer, IEssenceNFTEvents {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed id
    );

    UpgradeableBeacon internal beacon;
    address internal profile = address(0xdead);

    uint256 internal profileId = 18;
    uint256 internal essenceId = 90;
    string internal name = "1890's supporters";
    string internal symbol = "1890 GANG";

    EssenceNFT internal essence;

    address internal constant alice = address(0xA11CE);
    uint256 internal constant bobPk = 11111;
    address internal immutable bob = vm.addr(bobPk);

    EssenceNFT internal nonTransferableEssence;
    uint256 internal ntEssenceId = 91;
    string internal ntName = "1891's supporters";
    string internal ntSymbol = "1891 GANG";

    function setUp() public {
        BeaconProxy proxy;
        bytes memory functionData;
        address impl = deployEssence(_salt, profile);
        beacon = new UpgradeableBeacon(impl, address(profile));
        functionData = abi.encodeWithSelector(
            EssenceNFT.initialize.selector,
            profileId,
            essenceId,
            name,
            symbol,
            true
        );
        vm.expectEmit(true, true, false, true);
        emit Initialize(profileId, essenceId, name, symbol, true);
        proxy = new BeaconProxy(address(beacon), functionData);
        essence = EssenceNFT(address(proxy));

        functionData = abi.encodeWithSelector(
            EssenceNFT.initialize.selector,
            profileId,
            ntEssenceId,
            ntName,
            ntSymbol,
            false
        );
        proxy = new BeaconProxy(address(beacon), functionData);
        nonTransferableEssence = EssenceNFT(address(proxy));
    }

    function testBasic() public {
        assertEq(essence.name(), name);
        assertEq(essence.symbol(), symbol);

        assertEq(nonTransferableEssence.name(), ntName);
        assertEq(nonTransferableEssence.symbol(), ntSymbol);
    }

    function testMint() public {
        vm.prank(address(profile));
        assertEq(essence.mint(alice), 1);

        vm.prank(address(profile));
        assertEq(nonTransferableEssence.mint(alice), 1);
    }

    function testCannotMintAsNonProfile() public {
        vm.expectRevert("ONLY_PROFILE");
        essence.mint(alice);

        vm.expectRevert("ONLY_PROFILE");
        nonTransferableEssence.mint(alice);
    }

    function testPermitAndTransfer() public {
        vm.startPrank(address(profile));
        uint256 tokenId = essence.mint(bob);
        assertEq(essence.getApproved(tokenId), address(0));
        vm.warp(50);
        uint256 deadline = 100;
        bytes32 data = keccak256(
            abi.encode(
                Constants._PERMIT_TYPEHASH,
                alice,
                tokenId,
                essence.nonces(bob),
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
        emit Approval(bob, alice, tokenId);
        essence.permit(
            alice,
            tokenId,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
        assertEq(essence.getApproved(tokenId), alice);
        vm.stopPrank();
        // transfer initiated by permitted address
        vm.prank(alice);
        essence.transferFrom(bob, alice, tokenId);
        assertEq(essence.balanceOf(bob), 0);
        assertEq(essence.balanceOf(alice), 1);
        assertEq(essence.ownerOf(tokenId), alice);
    }

    function testCannotPermitAndTransferNonTransferableEssence() public {
        vm.startPrank(address(profile));
        uint256 tokenId = nonTransferableEssence.mint(bob);
        assertEq(nonTransferableEssence.getApproved(tokenId), address(0));
        vm.warp(50);
        uint256 deadline = 100;
        bytes32 data = keccak256(
            abi.encode(
                Constants._PERMIT_TYPEHASH,
                alice,
                tokenId,
                nonTransferableEssence.nonces(bob),
                deadline
            )
        );
        bytes32 digest = TestLib712.hashTypedDataV4(
            address(nonTransferableEssence),
            data,
            ntName,
            "1"
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(bobPk, digest);
        vm.expectEmit(true, true, true, true);
        emit Approval(bob, alice, tokenId);
        nonTransferableEssence.permit(
            alice,
            tokenId,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
        assertEq(nonTransferableEssence.getApproved(tokenId), alice);
        vm.stopPrank();
        // transfer initiated by permitted address
        vm.prank(alice);
        vm.expectRevert("TRANSFER_NOT_ALLOWED");
        nonTransferableEssence.transferFrom(bob, alice, tokenId);
        assertEq(nonTransferableEssence.balanceOf(bob), 1);
        assertEq(nonTransferableEssence.balanceOf(alice), 0);
        assertEq(nonTransferableEssence.ownerOf(tokenId), bob);
    }

    function testVersion() public {
        assertEq(essence.version(), 1);
        assertEq(nonTransferableEssence.version(), 1);
    }

    function testTokenURI() public {
        vm.prank(address(profile));
        assertEq(essence.mint(alice), 1);
        string memory tokenUri = "https://1890.com";
        vm.mockCall(
            address(profile),
            abi.encodeWithSelector(
                IProfileNFT.getEssenceNFTTokenURI.selector,
                profileId,
                essenceId
            ),
            abi.encode(tokenUri)
        );
        assertEq(essence.tokenURI(1), tokenUri);
    }

    function testTransfer() public {
        vm.prank(address(profile));
        uint256 tokenId = essence.mint(alice);
        assertEq(tokenId, 1);
        assertEq(essence.ownerOf(tokenId), alice);

        vm.prank(alice);
        essence.transferFrom(alice, bob, tokenId);
        assertEq(essence.balanceOf(alice), 0);
        assertEq(essence.balanceOf(bob), 1);
        assertEq(essence.ownerOf(tokenId), bob);
    }

    function testCannotTransferNontransferableEssence() public {
        vm.prank(address(profile));
        assertEq(nonTransferableEssence.mint(alice), 1);

        vm.expectRevert("TRANSFER_NOT_ALLOWED");
        nonTransferableEssence.transferFrom(alice, bob, 1);
        vm.expectRevert("TRANSFER_NOT_ALLOWED");
        nonTransferableEssence.safeTransferFrom(alice, bob, 1);
        vm.expectRevert("TRANSFER_NOT_ALLOWED");
        nonTransferableEssence.safeTransferFrom(alice, bob, 1, "");
    }
}
