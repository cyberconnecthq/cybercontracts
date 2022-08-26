// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { Owned } from "../dependencies/solmate/Owned.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "../dependencies/openzeppelin/ReentrancyGuard.sol";

import { Constants } from "../libraries/Constants.sol";
import { DataTypes } from "../libraries/DataTypes.sol";

import { EIP712 } from "../base/EIP712.sol";

/**
 * @title CyberVault
 * @author CyberConnect
 * @notice This contract is used to create CyberVault.
 */
contract CyberVault is Owned, ReentrancyGuard, EIP712 {
    using SafeERC20 for IERC20;

    event Initialize(address indexed owner);
    event Claim(
        uint256 indexed profileId,
        address indexed to,
        address indexed currency,
        uint256 amount
    );
    event Deposit(
        uint256 indexed profileId,
        address indexed currency,
        uint256 indexed amount
    );
    event SetSigner(address indexed preSigner, address indexed newSigner);

    address internal _signer;
    mapping(address => int256) public nonces;
    mapping(uint256 => mapping(address => uint256)) _balanceByProfileByCurrency;

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address owner) {
        _signer = owner;
        Owned.__Owned_Init(owner);
        ReentrancyGuard.__ReentrancyGuard_init();
        emit Initialize(owner);
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Claims ERC20 tokens from a profile's deposit.
     *
     * @param profileId The profile id.
     * @param to The claimer address.
     * @param currency The ERC20 address.
     * @param amount The amount to claim.
     * @param sig The EIP712 signature.
     */
    function claim(
        uint256 profileId,
        address to,
        address currency,
        uint256 amount,
        DataTypes.EIP712Signature calldata sig
    ) external nonReentrant {
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._CLAIM_TYPEHASH,
                        profileId,
                        to,
                        currency,
                        amount,
                        nonces[to]++,
                        sig.deadline
                    )
                )
            ),
            _signer,
            sig
        );

        require(
            _balanceByProfileByCurrency[profileId][currency] >= amount,
            "INSUFFICIENT_BALANCE"
        );

        _balanceByProfileByCurrency[profileId][currency] -= amount;

        IERC20(currency).safeTransfer(to, amount);
        emit Claim(profileId, to, currency, amount);
    }

    /**
     * @notice Deposit ERC20 tokens to a profile's balance.
     *
     * @param profileId The profile id.
     * @param currency The ERC20 address.
     * @param amount The amount to deposit.
     */
    function deposit(
        uint256 profileId,
        address currency,
        uint256 amount
    ) external nonReentrant {
        require(
            IERC20(currency).balanceOf(msg.sender) >= amount,
            "INSUFFICIENT_BALANCE"
        );
        IERC20(currency).safeTransferFrom(msg.sender, address(this), amount);

        _balanceByProfileByCurrency[profileId][currency] += amount;
        emit Deposit(profileId, currency, amount);
    }

    /**
     * @notice Sets the new signer address.
     *
     * @param signer The signer address.
     * @dev The address can not be zero address.
     */
    function setSigner(address signer) external onlyOwner {
        require(signer != address(0), "zero address signer");
        address preSigner = _signer;
        _signer = signer;

        emit SetSigner(preSigner, signer);
    }

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the signer address.
     *
     * @return address The signer address.
     */
    function getSigner() external view returns (address) {
        return _signer;
    }

    /**
     * @notice Gets the balance.
     *
     * @param profileId The profile id.
     * @param currency The ERC20 currency address.
     */
    function balanceOf(uint256 profileId, address currency)
        external
        view
        returns (uint256)
    {
        return _balanceByProfileByCurrency[profileId][currency];
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _domainSeparatorName()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return "CyberVault";
    }
}
