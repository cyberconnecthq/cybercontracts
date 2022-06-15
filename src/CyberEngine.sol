// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "solmate/auth/authorities/RolesAuthority.sol";
import "./dependencies/openzeppelin/EIP712.sol";
import { Authority } from "solmate/auth/Auth.sol";
import { DataTypes } from "./libraries/DataTypes.sol";
import { Constants } from "./libraries/Constants.sol";

contract CyberEngine is Auth, EIP712 {
    address public profileAddress;
    address public boxAddress;
    address public signer;

    constructor(
        address _owner,
        address _profileAddress,
        address _boxAddress,
        RolesAuthority _rolesAuthority
    ) EIP712("CyberEngine", "1.0.0") Auth(_owner, _rolesAuthority) {
        signer = _owner;
        profileAddress = _profileAddress;
        boxAddress = _boxAddress;
    }

    function register(
        address to,
        string calldata handle,
        DataTypes.EIP712Signature calldata sig
    ) public payable {
        _verify(to, handle, sig);
    }

    function _verify(
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

    function setSigner(address _signer) external requiresAuth {
        signer = _signer;
    }

    function setProfileAddress(address _profileAddress) external requiresAuth {
        profileAddress = _profileAddress;
    }

    function setBoxAddress(address _boxAddress) external requiresAuth {
        boxAddress = _boxAddress;
    }
}
