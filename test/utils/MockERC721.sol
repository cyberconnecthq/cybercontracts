// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract MockERC721 is ERC721 {
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        // mint four NFT tokens to msg.sender
        _mint(msg.sender, 1);
        _mint(msg.sender, 2);
        _mint(msg.sender, 3);
        _mint(msg.sender, 4);
    }
}
