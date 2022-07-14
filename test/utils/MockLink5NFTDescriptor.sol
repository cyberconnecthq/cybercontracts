// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IProfileNFTDescriptor } from "../../src/interfaces/IProfileNFTDescriptor.sol";
import { DataTypes } from "../../src/libraries/DataTypes.sol";

contract MockLink5NFTDescriptor is IProfileNFTDescriptor {
    function tokenURI(DataTypes.ConstructTokenURIParams calldata)
        external
        pure
        returns (string memory)
    {
        return "Link5TokenURI";
    }

    function setAnimationTemplate(string calldata template) external {}
}
