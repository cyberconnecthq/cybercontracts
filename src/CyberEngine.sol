// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "solmate/auth/authorities/RolesAuthority.sol";
import "./dependencies/openzeppelin/EIP712.sol";
import { IBoxNFT } from "./interfaces/IBoxNFT.sol";
import { IProfileNFT } from "./interfaces/IProfileNFT.sol";
import { Authority } from "solmate/auth/Auth.sol";
import { DataTypes } from "./libraries/DataTypes.sol";
import { Constants } from "./libraries/Constants.sol";

contract CyberEngine is Auth, EIP712 {
    address public profileAddress;
    address public boxAddress;
    address public signer;

    enum Tier {
        Tier0,
        Tier1,
        Tier2,
        Tier3,
        Tier4,
        Tier5
    }
    mapping(Tier => uint256) internal _feeMapping;

    constructor(
        address _owner,
        address _profileAddress,
        address _boxAddress,
        RolesAuthority _rolesAuthority
    ) EIP712("CyberEngine", "1.0.0") Auth(_owner, _rolesAuthority) {
        signer = _owner;
        profileAddress = _profileAddress;
        boxAddress = _boxAddress;
        _setInitialFees();
    }

    function setSigner(address _signer) external requiresAuth {
        signer = _signer;
    }

    function setProfileAddress(address _profileAddress) external requiresAuth {
        profileAddress = _profileAddress;
    }

    function setBoxAddress(address _boxAddress) external requiresAuth {
        boxAddress = _boxAddress;
    }

    function setFeeByTier(Tier tier, uint256 amount) external requiresAuth {
        _feeMapping[tier] = amount;
    }

    function register(
        address to,
        string calldata handle,
        DataTypes.EIP712Signature calldata sig
    ) external payable {
        _verifySignature(to, handle, sig);
        _requireEnoughFee(handle, msg.value);

        IBoxNFT(boxAddress).mint(to);
        IProfileNFT(profileAddress).createProfile(
            to,
            DataTypes.ProfileStruct(handle, "")
        );
    }

    function withdraw(address to, uint256 amount) external requiresAuth {
        uint256 balance = address(this).balance;
        require(balance >= amount, "Insufficient balance");
        payable(to).transfer(amount);
    }

    function getFeeByTier(Tier t) external view returns (uint256) {
        return _feeMapping[t];
    }

    function _setInitialFees() internal {
        _feeMapping[Tier.Tier0] = Constants._INITIAL_FEE_TIER0;
        _feeMapping[Tier.Tier1] = Constants._INITIAL_FEE_TIER1;
        _feeMapping[Tier.Tier2] = Constants._INITIAL_FEE_TIER2;
        _feeMapping[Tier.Tier3] = Constants._INITIAL_FEE_TIER3;
        _feeMapping[Tier.Tier4] = Constants._INITIAL_FEE_TIER4;
        _feeMapping[Tier.Tier5] = Constants._INITIAL_FEE_TIER5;
    }

    function _verifySignature(
        address to,
        string calldata handle,
        DataTypes.EIP712Signature calldata sig
    ) internal view {
        require(sig.deadline >= block.timestamp, "Deadline expired");
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(Constants._REGISTER, to, handle, sig.deadline))
        );

        address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);
        require(recoveredAddress == signer, "Invalid signature");
    }

    function _requireEnoughFee(string calldata handle, uint256 amount)
        internal
        view
    {
        bytes memory byteHandle = bytes(handle);
        uint256 fee = _feeMapping[Tier.Tier5];

        require(byteHandle.length >= 1, "Invalid handle length");
        if (byteHandle.length < 6) {
            fee = _feeMapping[Tier(byteHandle.length - 1)];
        }
        require(amount >= fee, "Insufficient fee");
    }
}
