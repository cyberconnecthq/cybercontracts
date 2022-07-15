// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";
import "./utils/MockNFT.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { Constants } from "../src/libraries/Constants.sol";
import { DataTypes } from "../src/libraries/DataTypes.sol";

import { TestLib712 } from "./utils/TestLib712.sol";

contract CyberNFTBaseTest is Test {
    MockNFT internal token;
    MockNFT internal impl;
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed id
    );

    address internal alice = address(0xA11CE);

    function setUp() public {
        impl = new MockNFT();
        bytes memory data = abi.encodeWithSelector(
            MockNFT.initialize.selector,
            "TestNFT",
            "TNFT"
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), data);
        token = MockNFT(address(proxy));
    }

    function testCannotInitializeImpl() public {
        vm.expectRevert("Contract already initialized");
        impl.initialize("TestNFT", "TNFT");
    }

    function testBasic() public {
        assertEq(token.name(), "TestNFT");
        assertEq(token.symbol(), "TNFT");
    }

    function testInternalMint() public {
        assertEq(token.totalSupply(), 0);
        token.mint(msg.sender);
        assertEq(token.totalSupply(), 1);
        assertEq(token.balanceOf(msg.sender), 1);
    }

    // should return token ID, should increment everytime we call
    function testReturnTokenId() public {
        assertEq(token.mint(msg.sender), 1);
        assertEq(token.mint(msg.sender), 2);
        assertEq(token.mint(msg.sender), 3);
    }

    function testDomainSeparator() public {
        bytes32 separator = token.DOMAIN_SEPARATOR();
        assertEq(
            separator,
            0x256e864a569c543568285877c820a2df690cff3cf09c54b7bddc5767f7545ccb
        );
    }

    function testPermit() public {
        uint256 bobPk = 11111;
        address bobAddr = vm.addr(bobPk);
        assertEq(token.mint(bobAddr), 1);
        vm.warp(50);
        uint256 deadline = 100;
        bytes32 data = keccak256(
            abi.encode(Constants._PERMIT_TYPEHASH, alice, 1, 0, deadline)
        );
        bytes32 digest = TestLib712.hashTypedDataV4(
            address(token),
            data,
            "TestNFT",
            "1"
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(bobPk, digest);
        vm.expectEmit(true, true, true, true);
        emit Approval(bobAddr, alice, 1);
        token.permit(alice, 1, DataTypes.EIP712Signature(v, r, s, deadline));
    }

    function testCannotPermitFromNonOwner() public {
        uint256 bobPk = 11111;
        address bobAddr = vm.addr(bobPk);
        uint256 charliePk = 22222;
        assertEq(token.mint(bobAddr), 1);
        vm.warp(50);
        uint256 deadline = 100;
        bytes32 data = keccak256(
            abi.encode(Constants._PERMIT_TYPEHASH, alice, 1, 0, deadline)
        );
        bytes32 digest = TestLib712.hashTypedDataV4(
            address(token),
            data,
            "TestNFT",
            "1"
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(charliePk, digest);
        vm.expectRevert("INVALID_SIGNATURE");
        token.permit(alice, 1, DataTypes.EIP712Signature(v, r, s, deadline));
    }

    function testCannotPermitOwner() public {
        uint256 bobPk = 11111;
        address bobAddr = vm.addr(bobPk);
        assertEq(token.mint(bobAddr), 1);
        vm.warp(50);
        uint256 deadline = 100;
        bytes32 data = keccak256(
            abi.encode(Constants._PERMIT_TYPEHASH, alice, 1, 0, deadline)
        );
        bytes32 digest = TestLib712.hashTypedDataV4(
            address(token),
            data,
            "TestNFT",
            "1"
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(bobPk, digest);
        vm.expectRevert("CANNOT_PERMIT_OWNER");
        token.permit(bobAddr, 1, DataTypes.EIP712Signature(v, r, s, deadline));
    }
}
