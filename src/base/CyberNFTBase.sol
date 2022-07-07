// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { ERC721 } from "../dependencies/solmate/ERC721.sol";
import { EIP712 } from "../dependencies/openzeppelin/EIP712.sol";
import { Initializable } from "../upgradeability/Initializable.sol";
import { ERC721 } from "../dependencies/solmate/ERC721.sol";
import { Constants } from "../libraries/Constants.sol";
import { DataTypes } from "../libraries/DataTypes.sol";
import { Lib712Check } from "../libraries/Lib712Check.sol";

// Sequential mint ERC721
// TODO: Put EIP712 permit logic here
// TODO: Might need to fork ERC721 for to store startTimeStamp like
// https://github.com/chiru-labs/ERC721A/blob/538817040d98c6464afa0be7cc625cef44776668/contracts/IERC721A.sol#L75
abstract contract CyberNFTBase is Initializable, EIP712, ERC721 {
    uint256 internal _totalCount = 0;
    mapping(address => uint256) public nonces;

    // TODO:
    // constructor() {
    //     _disableInitializers();
    // }

    function totalSupply() external view virtual returns (uint256) {
        return _totalCount;
    }

    function _initialize(
        string calldata _name,
        string calldata _symbol,
        string memory _version
    ) internal onlyInitializing {
        ERC721.__ERC721_Init(_name, _symbol);
        EIP712.__EIP712_Init(_name, _version);
    }

    function _mint(address _to) internal virtual returns (uint256) {
        super._mint(_to, ++_totalCount);
        return _totalCount;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf[tokenId] != address(0);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "NOT_MINTED");
    }

    // Permit
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return _domainSeparatorV4();
    }

    // Permit
    function permit(
        address spender,
        uint256 tokenId,
        DataTypes.EIP712Signature calldata sig
    ) external payable {
        address owner = ownerOf(tokenId);
        require(owner != spender, "CANNOT_PERMIT_OWNER");
        Lib712Check._requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._PERMIT_TYPEHASH,
                        spender,
                        tokenId,
                        nonces[owner]++,
                        sig.deadline
                    )
                )
            ),
            owner,
            sig
        );
        // approve and emit
        getApproved[tokenId] = spender;
        emit Approval(owner, spender, tokenId);
    }
}
