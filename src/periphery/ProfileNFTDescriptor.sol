// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { QRSVG } from "../libraries/QRSVG.sol";
import { LibString } from "../libraries/LibString.sol";
import { Base64 } from "../dependencies/openzeppelin/Base64.sol";
import { IProfileNFTDescriptor } from "../interfaces/IProfileNFTDescriptor.sol";

/**
 * @title Profile NFT Descriptor
 * @author CyberConnect
 * @notice This contract is used to create profile NFT token uri.
 */
contract ProfileNFTDescriptor is IProfileNFTDescriptor {
    /// @inheritdoc IProfileNFTDescriptor
    function tokenURI(ConstructTokenURIParams calldata params)
        external
        view
        override
        returns (string memory)
    {
        string memory formattedName = string(
            abi.encodePacked("@", params.handle)
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"',
                            formattedName,
                            '","description":"CyberConnect profile for ',
                            formattedName,
                            '","image":"',
                            params.imageURL,
                            '","animation_url":"',
                            params.animationURL,
                            '","attributes":',
                            genAttributes(
                                LibString.toString(params.tokenId),
                                LibString.toString(bytes(params.handle).length),
                                LibString.toString(params.subscribers),
                                formattedName
                            ),
                            // ',"qr_code":"',
                            // QRSVG.generateQRCode(
                            //     string(
                            //         abi.encodePacked("https://link3.to", handle)
                            //     )
                            // ),
                            // '"}'
                            "}"
                        )
                    )
                )
            );
    }

    function genAttributes(
        string memory tokenId,
        string memory length,
        string memory subscribers,
        string memory name
    ) private pure returns (bytes memory) {
        return
            abi.encodePacked(
                '[{"trait_type":"id","value":"',
                tokenId,
                '"},{"trait_type":"length","value":"',
                length,
                '"},{"trait_type":"subscribers","value":"',
                subscribers,
                '"},{"trait_type":"handle","value":"',
                name,
                '"}]'
            );
    }
}
