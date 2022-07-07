// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { StaticNFTSVG } from "../libraries/StaticNFTSVG.sol";
import { LibString } from "../libraries/LibString.sol";
import { Base64 } from "../dependencies/openzeppelin/Base64.sol";
import { IProfileNFTDescriptor } from "../interfaces/IProfileNFTDescriptor.sol";
import { Pausable } from "../dependencies/openzeppelin/Pausable.sol";
import { CyberEngine } from "../core/CyberEngine.sol";
import { Initializable } from "../upgradeability/Initializable.sol";

/**
 * @title Profile NFT Descriptor
 * @author CyberConnect
 * @notice This contract is used to create profile NFT token uri.
 */
contract ProfileNFTDescriptor is
    IProfileNFTDescriptor,
    Initializable,
    Pausable
{
    address public immutable ENGINE;
    string public _animationTemplate;

    modifier onlyEngine() {
        require(msg.sender == address(ENGINE), "Only Engine");
        _;
    }

    constructor(address engine) {
        require(engine != address(0), "Engine address cannot be 0");
        ENGINE = engine;
        _disableInitializers();
    }

    /**
     * @notice Initializes the Profile NFT Descriptor.
     *
     * @param animationTemplate Template animation url to set for the Profile NFT.
     */
    function initialize(string calldata animationTemplate)
        external
        initializer
    {
        _animationTemplate = animationTemplate;
        // start with paused
        _pause();
    }

    /// @inheritdoc IProfileNFTDescriptor
    function setAnimationTemplate(string calldata template)
        external
        override
        onlyEngine
    {
        _animationTemplate = template;
        emit SetAnimationTemplate(template);
    }

    /// @inheritdoc IProfileNFTDescriptor
    function getAnimationTemplate()
        external
        view
        override
        returns (string memory)
    {
        return _animationTemplate;
    }

    function tokenURI(ConstructTokenURIParams calldata params)
        external
        view
        override
        returns (string memory)
    {
        string memory formattedName = string(
            abi.encodePacked("@", params.handle)
        );

        string memory animationURL = string(
            abi.encodePacked(_animationTemplate, "?handle=", params.handle)
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
                            StaticNFTSVG.draw(params.handle),
                            '","animation_url":"',
                            animationURL,
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
