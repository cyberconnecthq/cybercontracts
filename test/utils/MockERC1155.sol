// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";

contract MockERC1155 is ERC1155 {
    constructor(string memory url) ERC1155(url) {}

    function mint(
        address to,
        uint256 tokenId,
        uint256 amount
    ) external {
        _mint(to, tokenId, amount, "");
    }
}
