// SPDX-License-Identifier: GPL-3.0
import "./LibString.sol";
import "../dependencies/openzeppelin/Base64.sol";

pragma solidity 0.8.14;

library QRSVG {
    uint256 constant SIZE = 29;

    struct QRMatrix {
        uint256[SIZE][SIZE] matrix;
        uint256[SIZE][SIZE] reserved;
    }

    // For testing, will change it to pure later
    function generateQRCode(string memory url)
        internal
        pure
        returns (string memory)
    {
        // 1. Create base matrix
        QRMatrix memory qrMatrix = createBaseMatrix();
        // 2. Encode Data
        uint8[] memory encoded = encode(url);
        // 3. Generate buff
        uint256[44] memory buf = generateBuf(encoded);

        // 4. Augument ECCs
        uint256[70] memory bufWithECCs = augumentECCs(buf);

        // 5. put data into matrix
        putData(qrMatrix, bufWithECCs);

        // 6. mask data
        maskData(qrMatrix);

        // 7. Put format info
        putFormatInfo(qrMatrix);
        // emit MatrixCreated(qrMatrix.matrix);

        // 8. Compose SVG and convert to base64
        string memory qrCodeUri = generateQRURI(qrMatrix);

        return qrCodeUri;
    }

    function maskData(QRMatrix memory _qrMatrix) internal pure {
        for (uint256 i = 0; i < SIZE; ++i) {
            for (uint256 j = 0; j < SIZE; ++j) {
                if (_qrMatrix.reserved[i][j] == 0) {
                    if (j % 3 == 0) {
                        _qrMatrix.matrix[i][j] ^= 1;
                    } else {
                        _qrMatrix.matrix[i][j] ^= 0;
                    }
                }
            }
        }
    }

    function generateBuf(uint8[] memory data)
        internal
        pure
        returns (uint256[44] memory)
    {
        uint256[44] memory buf;
        uint256 dataLen = data.length;
        uint8 maxBufLen = 55;

        uint256 bits = 0;
        uint256 remaining = 8;

        (buf, bits, remaining) = pack(buf, bits, remaining, 4, 4, 0);
        (buf, bits, remaining) = pack(buf, bits, remaining, dataLen, 8, 0);

        for (uint8 i = 0; i < dataLen; ++i) {
            (buf, bits, remaining) = pack(
                buf,
                bits,
                remaining,
                data[i],
                8,
                i + 1
            );
        }

        (buf, bits, remaining) = pack(buf, bits, remaining, 0, 4, dataLen + 1);

        for (uint256 i = data.length + 2; i < maxBufLen - 1; i++) {
            buf[i] = 0xec;
            buf[i + 1] = 0x11;
        }

        return buf;
    }

    function augumentECCs(uint256[44] memory poly)
        internal
        pure
        returns (uint256[70] memory)
    {
        uint8 nblocks = 1;
        uint8[15] memory genpoly = [
            8,
            183,
            61,
            91,
            202,
            37,
            51,
            58,
            58,
            237,
            140,
            124,
            5,
            99,
            105
        ];

        uint8[2] memory subsizes = [0, 44];
        uint256 nitemsperblock = 44;
        uint256[26][1] memory eccs;
        uint256[70] memory result;
        uint256[44] memory partPoly;

        for (uint256 i; i < 44; i++) {
            partPoly[i] = poly[i];
        }

        eccs[0] = calculateECC(partPoly, genpoly);

        for (uint8 i = 0; i < nitemsperblock; ++i) {
            for (uint8 j = 0; j < nblocks; ++j) {
                result[i] = poly[subsizes[j] + i];
            }
        }
        for (uint8 i = 0; i < genpoly.length; ++i) {
            for (uint8 j = 0; j < nblocks; ++j) {
                result[i + 44] = eccs[j][i];
            }
        }

        return result;
    }

    function calculateECC(uint256[44] memory poly, uint8[26] memory genpoly)
        internal
        pure
        returns (uint256[26] memory)
    {
        uint256[256] memory GF256_MAP;
        uint256[256] memory GF256_INVMAP;
        uint256[70] memory modulus;
        uint8 polylen = uint8(poly.length);
        uint8 genpolylen = uint8(genpoly.length);
        uint256[26] memory result;
        uint256 gf256_value = 1;

        GF256_INVMAP[0] = 0;

        for (uint256 i = 0; i < 255; ++i) {
            GF256_MAP[i] = gf256_value;
            GF256_INVMAP[gf256_value] = i;
            gf256_value = (gf256_value * 2) ^ (gf256_value >= 128 ? 0x11d : 0);
        }

        for (uint8 i = 0; i < 44; i++) {
            modulus[i] = poly[i];
        }

        for (uint8 i = 44; i < 70; ++i) {
            modulus[i] = 0;
        }

        for (uint8 i = 0; i < polylen; ) {
            uint256 idx = modulus[i++];
            if (idx > 0) {
                uint256 quotient = GF256_INVMAP[idx];
                for (uint8 j = 0; j < genpolylen; ++j) {
                    modulus[i + j] ^= GF256_MAP[(quotient + genpoly[j]) % 255];
                }
            }
        }

        for (uint8 i = 0; i < modulus.length - polylen; i++) {
            result[i] = modulus[polylen + i];
        }

        return result;
    }

    function pack(
        uint256[44] memory buf,
        uint256 bits,
        uint256 remaining,
        uint256 x,
        uint256 n,
        uint256 index
    )
        internal
        pure
        returns (
            uint256[44] memory,
            uint256,
            uint256
        )
    {
        uint256[44] memory newBuf = buf;
        uint256 newBits = bits;
        uint256 newRemaining = remaining;

        if (n >= remaining) {
            newBuf[index] = bits | (x >> (n -= remaining));
            newBits = 0;
            newRemaining = 8;
        }
        if (n > 0) {
            newBits |= (x & ((1 << n) - 1)) << (newRemaining -= n);
        }

        return (newBuf, newBits, newRemaining);
    }

    function encode(string memory str) internal pure returns (uint8[] memory) {
        bytes memory byteString = bytes(str);
        uint8[] memory encodedArr = new uint8[](byteString.length);

        for (uint8 i = 0; i < encodedArr.length; i++) {
            encodedArr[i] = uint8(byteString[i]);
        }

        return encodedArr;
    }

    function createBaseMatrix() internal pure returns (QRMatrix memory) {
        QRMatrix memory _qrMatrix;
        uint8[2] memory aligns = [4, 20];

        _qrMatrix = blit(
            _qrMatrix,
            0,
            0,
            9,
            9,
            [0x7f, 0x41, 0x5d, 0x5d, 0x5d, 0x41, 0x17f, 0x00, 0x40]
        );

        _qrMatrix = blit(
            _qrMatrix,
            SIZE - 8,
            0,
            8,
            9,
            [0x100, 0x7f, 0x41, 0x5d, 0x5d, 0x5d, 0x41, 0x7f, 0x00]
        );

        blit(
            _qrMatrix,
            0,
            SIZE - 8,
            9,
            8,
            [
                uint16(0xfe),
                uint16(0x82),
                uint16(0xba),
                uint16(0xba),
                uint16(0xba),
                uint16(0x82),
                uint16(0xfe),
                uint16(0x00),
                uint16(0x00)
            ]
        );

        for (uint256 i = 9; i < SIZE - 8; ++i) {
            _qrMatrix.matrix[6][i] = _qrMatrix.matrix[i][6] = ~i & 1;
            _qrMatrix.reserved[6][i] = _qrMatrix.reserved[i][6] = 1;
        }

        // alignment patterns
        for (uint8 i = 0; i < 2; ++i) {
            uint8 minj = i == 0 || i == 1 ? 1 : 0;
            uint8 maxj = i == 0 ? 1 : 2;
            for (uint8 j = minj; j < maxj; ++j) {
                blit(
                    _qrMatrix,
                    aligns[i],
                    aligns[j],
                    5,
                    5,
                    [
                        uint16(0x1f),
                        uint16(0x11),
                        uint16(0x15),
                        uint16(0x11),
                        uint16(0x1f),
                        uint16(0x00),
                        uint16(0x00),
                        uint16(0x00),
                        uint16(0x00)
                    ]
                );
            }
        }

        return _qrMatrix;
    }

    function blit(
        QRMatrix memory qrMatrix,
        uint256 y,
        uint256 x,
        uint256 h,
        uint256 w,
        uint16[9] memory data
    ) internal pure returns (QRMatrix memory) {
        for (uint256 i = 0; i < h; ++i) {
            for (uint256 j = 0; j < w; ++j) {
                qrMatrix.matrix[y + i][x + j] = (data[i] >> j) & 1;
                qrMatrix.reserved[y + i][x + j] = 1;
            }
        }

        return qrMatrix;
    }

    function putFormatInfo(QRMatrix memory _qrMatrix) internal pure {
        uint8[15] memory infoA = [
            0,
            1,
            2,
            3,
            4,
            5,
            7,
            8,
            22,
            23,
            24,
            25,
            26,
            27,
            28
        ];

        uint8[15] memory infoB = [
            28,
            27,
            26,
            25,
            24,
            23,
            22,
            21,
            7,
            5,
            4,
            3,
            2,
            1,
            0
        ];

        for (uint8 i = 0; i < 15; ++i) {
            uint8 r = infoA[i];
            uint8 c = infoB[i];
            _qrMatrix.matrix[r][8] = _qrMatrix.matrix[8][c] = (32170 >> i) & 1;
            // we don't have to mark those bits reserved; always done
            // in makebasematrix above.
        }
    }

    function putData(QRMatrix memory _qrMatrix, uint256[70] memory data)
        internal
        pure
        returns (QRMatrix memory)
    {
        uint256 k = 0;
        int8 dir = -1;

        // i will go below 0
        for (int256 i = int256(SIZE - 1); i >= 0; i = i - 2) {
            // skip the entire timing pattern column
            if (i == 6) {
                --i;
            }
            int256 jj = dir < 0 ? int256(SIZE - 1) : int256(0);
            for (uint256 j = 0; j < SIZE; j++) {
                // ii  will go below 0
                for (int256 ii = int256(i); ii > int256(i) - 2; ii--) {
                    // uint256(jj) and uint256(ii) will never underflow here
                    if (
                        _qrMatrix.reserved[uint256(jj)][uint256(ii)] == 0 &&
                        k >> 3 < 70
                    ) {
                        _qrMatrix.matrix[uint256(jj)][uint256(ii)] =
                            (data[k >> 3] >> (~k & 7)) &
                            1;
                        ++k;
                    }
                }

                if (dir == -1) {
                    // jj will go below 0 at end of loop
                    jj = jj - 1;
                } else {
                    jj = jj + 1;
                }
            }

            dir = -dir;
        }

        return _qrMatrix;
    }

    function generateQRURI(QRMatrix memory _qrMatrix)
        internal
        pure
        returns (string memory)
    {
        bytes memory QRCodeURI = bytes(
            '<svg viewBox="0 0 74 74" style="shape-rendering:crispEdges" xmlns="http://www.w3.org/2000/svg"><style>.bg{fill:#FFF}</style><rect class="bg" x="0" y="0" width="74" height="74"></rect>'
        );

        uint256 yo = 8;
        for (uint256 y = 0; y < SIZE; ++y) {
            uint256 xo = 0;
            uint256 xe = 0;
            for (uint256 x = 0; x < SIZE; ++x) {
                if (_qrMatrix.matrix[y][x] == 1) {
                    if (xo == 0) {
                        xo = 8 + x * 2;
                        xe = xo + 2;
                    } else {
                        xe += 2;
                    }
                } else if (xo != 0) {
                    QRCodeURI = (
                        abi.encodePacked(
                            QRCodeURI,
                            '<rect x="',
                            LibString.toString(xo),
                            '" y="',
                            LibString.toString(yo),
                            '" width="',
                            LibString.toString(xe - xo),
                            '"  height="2" />'
                        )
                    );
                    xo = 0;
                    xe = 0;
                }
            }
            if (xo != 0) {
                QRCodeURI = (
                    abi.encodePacked(
                        QRCodeURI,
                        '<rect x="',
                        LibString.toString(xo),
                        '" y="',
                        LibString.toString(yo),
                        '" width="',
                        LibString.toString(xe - xo),
                        '"  height="2" />'
                    )
                );
            }
            yo += 2;
        }

        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(abi.encodePacked(QRCodeURI, "</svg>"))
                )
            );
    }
}
