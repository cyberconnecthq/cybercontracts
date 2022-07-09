// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { StaticNFTSVG } from "../libraries/StaticNFTSVG.sol";
import { LibString } from "../libraries/LibString.sol";
import { Base64 } from "../dependencies/openzeppelin/Base64.sol";
import { IProfileNFTDescriptor } from "../interfaces/IProfileNFTDescriptor.sol";
import { Initializable } from "../upgradeability/Initializable.sol";

/**
 * @title Profile NFT Descriptor
 * @author CyberConnect
 * @notice This contract is used to create profile NFT token uri.
 */
contract ProfileNFTDescriptor is IProfileNFTDescriptor, Initializable {
    address public immutable PROFILE; // solhint-disable-line
    string public animationTemplate;

    constructor(address profile) {
        require(profile != address(0), "PROFILE_ADDRESS_CANNOT_BE_0");
        PROFILE = profile;
        _disableInitializers();
    }

    /**
     * @notice Initializes the Profile NFT Descriptor.
     *
     * @param _animationTemplate Template animation url to set for the Profile NFT.
     */
    function initialize(string calldata _animationTemplate)
        external
        initializer
    {
        animationTemplate = _animationTemplate;
    }

    /// @inheritdoc IProfileNFTDescriptor
    function setAnimationTemplate(string calldata template) external override {
        require(msg.sender == PROFILE, "ONLY_PROFILE");
        animationTemplate = template;
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
            abi.encodePacked(animationTemplate, "?handle=", params.handle)
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
