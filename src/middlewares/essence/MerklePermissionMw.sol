// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { MerkleProof } from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

import { IEssenceMiddleware } from "../../interfaces/IEssenceMiddleware.sol";

/**
 * @title MerklePermission Middleware
 * @author CyberConnect
 * @notice This contract is a middleware to only allow users to collect an essence given the correct merkle proof
 */
contract MerklePermissionMw is IEssenceMiddleware {
    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => mapping(uint256 => bytes32))) rootStorage;

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IEssenceMiddleware
     * @notice Stores the root info when the Essence is registered
     */
    function setEssenceMwData(
        uint256 profileId,
        uint256 essenceId,
        bytes calldata root
    ) external override returns (bytes memory) {
        rootStorage[msg.sender][profileId][essenceId] = abi.decode(
            root,
            (bytes32)
        );
        return new bytes(0);
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IEssenceMiddleware
     * @notice Proccess that checks if the collect is in the root given the correct proof
     */
    function preProcess(
        uint256 profileId,
        uint256 essenceId,
        address collector,
        address,
        bytes calldata proof
    ) external view override {
        require(
            _verify(
                _leaf(collector),
                rootStorage[msg.sender][profileId][essenceId],
                abi.decode(proof, (bytes32[]))
            ) == true,
            "INVALID_PROOF"
        );
    }

    /// @inheritdoc IEssenceMiddleware
    function postProcess(
        uint256,
        uint256,
        address,
        address,
        bytes calldata
    ) external {
        // do nothing
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _leaf(address to) internal pure returns (bytes32) {
        return keccak256(abi.encode(to));
    }

    function _verify(
        bytes32 leaf,
        bytes32 root,
        bytes32[] memory proof
    ) internal pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }
}