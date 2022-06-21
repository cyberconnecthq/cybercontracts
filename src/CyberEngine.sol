// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./dependencies/openzeppelin/EIP712.sol";
import "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "./upgradeability/Initializable.sol";
import { IBoxNFT } from "./interfaces/IBoxNFT.sol";
import { IProfileNFT } from "./interfaces/IProfileNFT.sol";
import { Auth } from "./base/Auth.sol";
import { RolesAuthority } from "./base/RolesAuthority.sol";
import { DataTypes } from "./libraries/DataTypes.sol";
import { Constants } from "./libraries/Constants.sol";

contract CyberEngine is Initializable, Auth, EIP712, UUPSUpgradeable {
    address public profileAddress;
    address public boxAddress;
    address public signer;
    bool public boxOpened;
    mapping(address => uint256) public nonces;

    string internal constant VERSION_STRING = "1";
    uint256 internal constant VERSION = 1;

    enum Tier {
        Tier0,
        Tier1,
        Tier2,
        Tier3,
        Tier4,
        Tier5
    }
    mapping(Tier => uint256) public feeMapping;

    function initialize(
        address _owner,
        address _profileAddress,
        address _boxAddress,
        RolesAuthority _rolesAuthority
    ) external initializer {
        Auth.__Auth_Init(_owner, _rolesAuthority);
        EIP712.__EIP712_Init("CyberEngine", VERSION_STRING);

        signer = _owner;
        profileAddress = _profileAddress;
        boxAddress = _boxAddress;
        boxOpened = false;
        _setInitialFees();
    }

    function setSigner(address _signer) external requiresAuth {
        require(_signer != address(0), "zero address signer");
        signer = _signer;
    }

    function setProfileAddress(address _profileAddress) external requiresAuth {
        require(_profileAddress != address(0), "zero address profile");
        profileAddress = _profileAddress;
    }

    function setBoxAddress(address _boxAddress) external requiresAuth {
        require(_boxAddress != address(0), "zero address box");
        boxAddress = _boxAddress;
    }

    function setFeeByTier(Tier tier, uint256 amount) external requiresAuth {
        feeMapping[tier] = amount;
    }

    function setBoxOpened(bool opened) external requiresAuth {
        boxOpened = opened;
    }

    function register(
        address to,
        string calldata handle,
        DataTypes.EIP712Signature calldata sig
    ) external payable {
        _verifySignature(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._REGISTER,
                        to,
                        handle,
                        nonces[to]++,
                        sig.deadline
                    )
                )
            ),
            sig
        );

        _requireEnoughFee(handle, msg.value);

        if (!boxOpened) {
            IBoxNFT(boxAddress).mint(to);
        }
        IProfileNFT(profileAddress).createProfile(
            to,
            DataTypes.ProfileStruct(handle, "")
        );
    }

    function withdraw(address to, uint256 amount) external requiresAuth {
        require(to != address(0), "withdraw to the zero address");
        uint256 balance = address(this).balance;
        require(balance >= amount, "Insufficient balance");
        payable(to).transfer(amount);
    }

    function _setInitialFees() internal {
        feeMapping[Tier.Tier0] = Constants._INITIAL_FEE_TIER0;
        feeMapping[Tier.Tier1] = Constants._INITIAL_FEE_TIER1;
        feeMapping[Tier.Tier2] = Constants._INITIAL_FEE_TIER2;
        feeMapping[Tier.Tier3] = Constants._INITIAL_FEE_TIER3;
        feeMapping[Tier.Tier4] = Constants._INITIAL_FEE_TIER4;
        feeMapping[Tier.Tier5] = Constants._INITIAL_FEE_TIER5;
    }

    function _verifySignature(
        bytes32 digest,
        DataTypes.EIP712Signature calldata sig
    ) internal view {
        require(sig.deadline >= block.timestamp, "Deadline expired");
        address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);
        require(recoveredAddress == signer, "Invalid signature");
    }

    function _requireEnoughFee(string calldata handle, uint256 amount)
        internal
        view
    {
        bytes memory byteHandle = bytes(handle);
        uint256 fee = feeMapping[Tier.Tier5];

        require(byteHandle.length >= 1, "Invalid handle length");
        if (byteHandle.length < 6) {
            fee = feeMapping[Tier(byteHandle.length - 1)];
        }
        require(amount >= fee, "Insufficient fee");
    }

    // UUPS upgradeability
    function version() external pure virtual returns (uint256) {
        return VERSION;
    }

    // UUPS upgradeability
    function _authorizeUpgrade(address) internal override requiresAuth {}
}
