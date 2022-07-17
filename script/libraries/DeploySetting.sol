// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

contract DeploySetting {
    struct DeployParameters {
        address link3Owner; // sets nft descriptor
        address link3Signer; // signs for profile registration
        address link3Treasury; // collect registration fees
        address engineAuthOwner; // sets role auth role and cap
        address engineGov; // engine gov to create namespace
        address engineTreasury; // collect protocol fees
        address deployerContract; // used to deploy contracts
    }

    DeployParameters internal deployParams;

    function _setDeployParams() internal {
        if (block.chainid == 31337) {
            // use the same address that runs the deployment script
            deployParams.link3Owner = address(
                0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
            );
            deployParams.link3Signer = address(
                0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
            );
            deployParams.link3Treasury = address(
                0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
            );
            deployParams.engineAuthOwner = address(
                0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
            );
            deployParams.engineGov = address(
                0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
            );
            deployParams.engineTreasury = address(
                0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
            );
            deployParams.deployerContract = address(0);
        } else if (block.chainid == 5) {
            deployParams.link3Owner = address(
                0x927f355117721e0E8A7b5eA20002b65B8a551890
            );
            deployParams.link3Signer = address(
                0xaB24749c622AF8FC567CA2b4d3EC53019F83dB8F
            );
            deployParams.link3Treasury = address(
                0x927f355117721e0E8A7b5eA20002b65B8a551890
            );
            deployParams.engineAuthOwner = address(
                0x927f355117721e0E8A7b5eA20002b65B8a551890
            );
            deployParams.engineGov = address(
                0x927f355117721e0E8A7b5eA20002b65B8a551890
            );
            deployParams.engineTreasury = address(
                0x927f355117721e0E8A7b5eA20002b65B8a551890
            );
            deployParams.deployerContract = address(0);
        }
    }
}
