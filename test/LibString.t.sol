// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";

import { LibString } from "../src/libraries/LibString.sol";

contract LibStringTest is Test {
    function testToStringZero() public {
        assertEq(
            keccak256(bytes(LibString.toString(0))),
            keccak256(bytes("0"))
        );
    }

    function testToStringPositiveNumber() public {
        assertEq(
            keccak256(bytes(LibString.toString(4132))),
            keccak256(bytes("4132"))
        );
    }

    function testToStringUint256Max() public {
        assertEq(
            keccak256(bytes(LibString.toString(type(uint256).max))),
            keccak256(
                bytes(
                    "115792089237316195423570985008687907853269984665640564039457584007913129639935"
                )
            )
        );
    }

    function testToHexStringZero() public {
        assertEq(
            keccak256(bytes(LibString.toHexString(0))),
            keccak256(bytes("0x00"))
        );
    }

    function testToHexStringPositiveNumber() public {
        assertEq(
            keccak256(bytes(LibString.toHexString(0x4132))),
            keccak256(bytes("0x4132"))
        );
    }

    function testToHexStringUint256Max() public {
        assertEq(
            keccak256(bytes(LibString.toHexString(type(uint256).max))),
            keccak256(
                bytes(
                    "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
                )
            )
        );
    }

    function testToHexStringFixedLengthPositiveNumberLong() public {
        assertEq(
            keccak256(bytes(LibString.toHexString(0x4132, 32))),
            keccak256(
                bytes(
                    "0x0000000000000000000000000000000000000000000000000000000000004132"
                )
            )
        );
    }

    function testToHexStringFixedLengthPositiveNumberShort() public {
        assertEq(
            keccak256(bytes(LibString.toHexString(0x4132, 2))),
            keccak256(bytes("0x4132"))
        );
    }

    function testToHexStringFixedLengthInsufficientLength() public {
        vm.expectRevert("HEX_LENGTH_INSUFFICIENT");
        LibString.toHexString(0x4132, 1);
    }

    function testToHexStringFixedLengthUint256Max() public {
        assertEq(
            keccak256(bytes(LibString.toHexString(type(uint256).max, 32))),
            keccak256(
                bytes(
                    "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
                )
            )
        );
    }

    function testFromAddressToHexString() public {
        assertEq(
            keccak256(
                bytes(
                    LibString.toHexString(
                        address(0xA9036907dCcae6a1E0033479B12E837e5cF5a02f)
                    )
                )
            ),
            keccak256(bytes("0xa9036907dccae6a1e0033479b12e837e5cf5a02f"))
        );
    }

    function testFromAddressToHexStringWithLeadingZeros() public {
        assertEq(
            keccak256(
                bytes(
                    LibString.toHexString(
                        address(0x0000E0Ca771e21bD00057F54A68C30D400000000)
                    )
                )
            ),
            keccak256(bytes("0x0000e0ca771e21bd00057f54a68c30d400000000"))
        );
    }

    function testToLowerLetterOnly() public {
        assertEq(LibString.toLower("ALICE"), "alice");
    }

    function testToLowerLetterMixed() public {
        assertEq(LibString.toLower("ALICE_+%12345_abc"), "alice_+%12345_abc");
    }

    function testToUpperLetterOnly() public {
        assertEq(LibString.toUpper("alice"), "ALICE");
    }

    function testToUpperLetterMixed() public {
        assertEq(LibString.toUpper("ALICE_+%12345_abc"), "ALICE_+%12345_ABC");
    }
}
