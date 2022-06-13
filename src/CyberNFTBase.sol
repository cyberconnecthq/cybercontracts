// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import { ERC721 } from "solmate/tokens/ERC721.sol";

// Sequential mint ERC721
// TODO: Put EIP712 permit logic here
// TODO: Might need to fork ERC721 for to store startTimeStamp like
// https://github.com/chiru-labs/ERC721A/blob/538817040d98c6464afa0be7cc625cef44776668/contracts/IERC721A.sol#L75
abstract contract CyberNFTBase is ERC721 {
    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    uint256 internal _totalCount = 0;

    function totalSupply() external view virtual returns (uint256) {
        return _totalCount;
    }

    function _mint(address _to) internal virtual {
        super._mint(_to, ++_totalCount);
    }
}
