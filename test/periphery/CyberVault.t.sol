// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";

import { Constants } from "../../src/libraries/Constants.sol";
import { DataTypes } from "../../src/libraries/DataTypes.sol";

import { TestLib712 } from "../utils/TestLib712.sol";
import { MockERC20 } from "../utils/MockERC20.sol";
import { MockERC721 } from "../utils/MockERC721.sol";
import { MockERC1155 } from "../utils/MockERC1155.sol";
import { CyberVault } from "../../src/periphery/CyberVault.sol";

contract CyberVaultTest is Test {
    event Initialize(address indexed owner);
    event Claim(
        uint256 indexed profileId,
        address indexed to,
        address indexed currency,
        uint256 amount
    );
    event Deposit(
        uint256 indexed profileId,
        address indexed currency,
        uint256 indexed amount
    );
    event SetSigner(address indexed preSigner, address indexed newSigner);

    CyberVault internal vault;
    MockERC20 internal token;
    MockERC721 internal nft721;
    MockERC1155 internal nft1155;

    address constant signer = address(0xA11CE);
    address constant owner = address(0xe);
    address constant bob = address(0xB0B);
    uint256 constant tokenId = 888;

    function setUp() public {
        vault = new CyberVault(owner);
        token = new MockERC20("Test Coin", "TC");
        nft721 = new MockERC721("CyberPunk", "CP");
        nft1155 = new MockERC1155("url");

        token.mint(bob, 200);
        nft721.mint(bob, tokenId);
        nft1155.mint(bob, tokenId, 200);
    }

    function testBasic() public {
        assertEq(vault.getSigner(), owner);
    }

    function testCannotSetSignerNonOwner() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(address(0));
        vault.setSigner(signer);
    }

    function testCannotSetOwnerNonOwner() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(address(0));
        vault.setOwner(signer);
    }

    function testSetSigner() public {
        vm.prank(owner);

        vm.expectEmit(true, true, false, true);
        emit SetSigner(owner, signer);
        vault.setSigner(signer);
    }

    function testSetOwner() public {
        vm.prank(owner);
        vault.setOwner(bob);
    }

    function testDeposit() public {
        vm.startPrank(bob);
        assertEq(token.balanceOf(bob), 200);

        string memory profileId = "1";
        uint256 amount = 50;

        token.approve(address(vault), amount);
        vault.deposit(profileId, address(token), amount);

        assertEq(token.balanceOf(bob), 200 - amount);
        assertEq(vault.balanceOf(profileId, address(token)), amount);
    }

    function testDeposit721() public {
        vm.startPrank(bob);
        assertEq(nft721.ownerOf(tokenId), bob);

        string memory profileId = "1";

        nft721.approve(address(vault), tokenId);
        vault.deposit721(profileId, address(nft721), tokenId);

        assertEq(nft721.ownerOf(tokenId), address(vault));
    }

    function testDeposit1155() public {
        vm.startPrank(bob);
        assertEq(nft1155.balanceOf(bob, tokenId), 200);

        string memory profileId = "1";

        nft1155.setApprovalForAll(address(vault), true);
        vault.deposit1155(profileId, address(nft1155), tokenId, 50);

        assertEq(nft1155.balanceOf(bob, tokenId), 150);
        assertEq(nft1155.balanceOf(address(vault), tokenId), 50);
    }

    function testDepositInsufficientBal() public {
        vm.startPrank(bob);
        assertEq(token.balanceOf(bob), 200);

        string memory profileId = "1";
        token.approve(address(vault), 1000);

        vm.expectRevert("INSUFFICIENT_BALANCE");
        vault.deposit(profileId, address(token), 1000);

        assertEq(token.balanceOf(bob), 200);
        assertEq(vault.balanceOf(profileId, address(token)), 0);
    }

    function testClaim() public {
        address charlie = vm.addr(1);
        vm.prank(owner);
        vault.setSigner(charlie);

        string memory profileId = "1";
        uint256 deposit = 1000;
        uint256 claim = 300;
        uint256 bobInitBal = 200;

        token.approve(address(vault), deposit);
        vault.deposit(profileId, address(token), deposit);

        assertEq(vault.balanceOf(profileId, address(token)), deposit);
        assertEq(token.balanceOf(bob), bobInitBal);
        assertEq(vault.nonces(bob), 0);

        vm.warp(50);
        uint256 deadline = 100;
        bytes32 digest = TestLib712.hashTypedDataV4(
            address(vault),
            keccak256(
                abi.encode(
                    Constants._CLAIM_TYPEHASH,
                    keccak256(bytes(profileId)),
                    bob,
                    address(token),
                    claim,
                    0,
                    deadline
                )
            ),
            "CyberVault",
            "1"
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);
        vault.claim(
            profileId,
            bob,
            address(token),
            claim,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );

        assertEq(vault.balanceOf(profileId, address(token)), deposit - claim);
        assertEq(token.balanceOf(bob), bobInitBal + claim);
        assertEq(vault.nonces(bob), 1);
    }

    function testClaim721() public {
        address charlie = vm.addr(1);
        vm.prank(owner);
        vault.setSigner(charlie);

        string memory profileId = "1";

        vm.startPrank(bob);

        nft721.approve(address(vault), tokenId);
        vault.deposit721(profileId, address(nft721), tokenId);

        assertEq(vault.nftBalanceOf(profileId, address(nft721), tokenId), 1);
        assertEq(nft721.ownerOf(tokenId), address(vault));
        assertEq(vault.nonces(bob), 0);

        vm.warp(50);
        uint256 deadline = 100;
        bytes32 digest = TestLib712.hashTypedDataV4(
            address(vault),
            keccak256(
                abi.encode(
                    Constants._CLAIM721_TYPEHASH,
                    keccak256(bytes(profileId)),
                    bob,
                    address(nft721),
                    tokenId,
                    0,
                    deadline
                )
            ),
            "CyberVault",
            "1"
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);
        vault.claim721(
            profileId,
            bob,
            address(nft721),
            tokenId,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );

        assertEq(vault.nftBalanceOf(profileId, address(token), tokenId), 0);
        assertEq(nft721.ownerOf(tokenId), bob);
        assertEq(vault.nonces(bob), 1);
    }

    function testClaim1155() public {
        address charlie = vm.addr(1);
        vm.prank(owner);
        vault.setSigner(charlie);

        string memory profileId = "1";
        uint256 deposit = 50;
        uint256 initAmount = 200;
        uint256 claim = 30;

        vm.startPrank(bob);

        nft1155.setApprovalForAll(address(vault), true);
        vault.deposit1155(profileId, address(nft1155), tokenId, deposit);

        assertEq(
            vault.nftBalanceOf(profileId, address(nft1155), tokenId),
            deposit
        );
        assertEq(nft1155.balanceOf(bob, tokenId), initAmount - deposit);
        assertEq(nft1155.balanceOf(address(vault), tokenId), deposit);
        assertEq(vault.nonces(bob), 0);

        vm.warp(50);
        uint256 deadline = 100;
        bytes32 digest = TestLib712.hashTypedDataV4(
            address(vault),
            keccak256(
                abi.encode(
                    Constants._CLAIM1155_TYPEHASH,
                    keccak256(bytes(profileId)),
                    bob,
                    address(nft1155),
                    tokenId,
                    claim,
                    0,
                    deadline
                )
            ),
            "CyberVault",
            "1"
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);
        vault.claim1155(
            profileId,
            bob,
            address(nft1155),
            tokenId,
            claim,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );

        assertEq(
            vault.nftBalanceOf(profileId, address(nft1155), tokenId),
            deposit - claim
        );
        assertEq(nft1155.balanceOf(bob, tokenId), initAmount - deposit + claim);
        assertEq(nft1155.balanceOf(address(vault), tokenId), deposit - claim);
        assertEq(vault.nonces(bob), 1);
    }

    function testClaimInsufficientBal() public {
        address charlie = vm.addr(1);
        vm.prank(owner);
        vault.setSigner(charlie);

        string memory profileId = "1";
        uint256 deposit = 0;
        uint256 claim = 300;
        uint256 bobInitBal = 200;

        assertEq(vault.balanceOf(profileId, address(token)), deposit);
        assertEq(token.balanceOf(bob), bobInitBal);

        vm.warp(50);
        uint256 deadline = 100;
        bytes32 digest = TestLib712.hashTypedDataV4(
            address(vault),
            keccak256(
                abi.encode(
                    Constants._CLAIM_TYPEHASH,
                    keccak256(bytes(profileId)),
                    bob,
                    address(token),
                    claim,
                    0,
                    deadline
                )
            ),
            "CyberVault",
            "1"
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);

        vm.expectRevert("INSUFFICIENT_BALANCE");
        vault.claim(
            profileId,
            bob,
            address(token),
            claim,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );

        assertEq(vault.balanceOf(profileId, address(token)), deposit);
        assertEq(token.balanceOf(bob), bobInitBal);
    }

    function testClaimInvalidSig() public {
        address charlie = vm.addr(1);
        vm.prank(owner);
        vault.setSigner(charlie);

        string memory profileId = "1";
        uint256 deposit = 1000;
        uint256 claim = 300;

        token.approve(address(vault), deposit);
        vault.deposit(profileId, address(token), deposit);

        vm.warp(50);
        uint256 deadline = 100;
        bytes32 digest = TestLib712.hashTypedDataV4(
            address(vault),
            keccak256(
                abi.encode(
                    Constants._CLAIM_TYPEHASH,
                    keccak256(bytes(profileId)),
                    bob,
                    address(token),
                    claim + 200,
                    0,
                    deadline
                )
            ),
            "CyberVault",
            "1"
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);
        vm.expectRevert("INVALID_SIGNATURE");
        vault.claim(
            profileId,
            bob,
            address(token),
            claim,
            DataTypes.EIP712Signature(v, r, s, deadline)
        );
    }
}
