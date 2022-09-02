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
        address cyberTokenOwner; // cyber token owner
    }

    DeployParameters internal deployParams;

    function _setDeployParams() internal {
        // Anvil accounts
        // (0) 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 (10000 ETH)
        // (1) 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 (10000 ETH)
        // (2) 0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc (10000 ETH)

        // Testnet accounts
        // deployer: 0x927f355117721e0E8A7b5eA20002b65B8a551890
        // engine treasury: 0x1890a1625d837A809b0e77EdE1a999a161df085d
        // link3 treasury + signer: 0xaB24749c622AF8FC567CA2b4d3EC53019F83dB8F
        if (block.chainid == 31337) {
            // use the same address that runs the deployment script
            deployParams.link3Owner = address(
                0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
            );
            deployParams.link3Signer = address(
                0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
            );
            deployParams.link3Treasury = address(
                0x70997970C51812dc3A010C7d01b50e0d17dc79C8 // use different wallet to pass balance delta check
            );
            deployParams.engineAuthOwner = address(
                0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
            );
            deployParams.engineGov = address(
                0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
            );
            deployParams.engineTreasury = address(
                0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC // use different wallet to pass balance delta check (gas paying)
            );
            deployParams.cyberTokenOwner = address(
                0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
            );
            deployParams.deployerContract = address(0);
        } else if (block.chainid == 5 || block.chainid == 4) {
            // goerli
            deployParams.link3Owner = address(
                // 0x1890a1625d837A809b0e77EdE1a999a161df085d
                0x927f355117721e0E8A7b5eA20002b65B8a551890
            );
            deployParams.link3Signer = address(
                0xaB24749c622AF8FC567CA2b4d3EC53019F83dB8F
            );
            deployParams.link3Treasury = address(
                0xF17CacbD8ca7e4Ec46F98C0eB898C0F0DEA07802
            );
            deployParams.engineAuthOwner = address(
                0x927f355117721e0E8A7b5eA20002b65B8a551890
            );
            deployParams.engineGov = address(
                0x927f355117721e0E8A7b5eA20002b65B8a551890
            );
            deployParams.engineTreasury = address(
                0x78020361856816382501E444600A29519fb3B107
            );
            deployParams.cyberTokenOwner = address(
                0x78020361856816382501E444600A29519fb3B107
            );
            //goerli
            if (block.chainid == 5) {
                deployParams.deployerContract = address(
                    0xeE048722AE9F11EFE0E233c9a53f2CaD141acF51
                );
            } else if (block.chainid == 4) {
                deployParams.deployerContract = address(
                    0xe19061D4Dd38ac3B67eeC28E90bdFB68065DbF7c
                );
            }
        } else if (
            block.chainid == 1 || block.chainid == 137 || block.chainid == 56
        ) {
            deployParams.link3Owner = address(
                0x39e0c6E610A8D7F408dD688011591583cbc1c3ce
            );
            deployParams.link3Signer = address(
                0x2A2EA826102c067ECE82Bc6E2B7cf38D7EbB1B82
            );
            deployParams.link3Treasury = address(
                0xe75Fe33b0fB1441a11C5c1296e5Ca83B72cfE00d
            );
            deployParams.engineAuthOwner = address(
                0xA7b6bEf855c1c57Df5b7C9c7a4e1eB757e544e7f
            );
            deployParams.engineGov = address(
                0xA7b6bEf855c1c57Df5b7C9c7a4e1eB757e544e7f
            );
            deployParams.engineTreasury = address(
                0xa4E52748fAcCA028D163941f3Bd52F4B204f8019
            );
            deployParams.cyberTokenOwner = address(
                0xa4E52748fAcCA028D163941f3Bd52F4B204f8019 // TODO: change to gnosis wallet
            );
            deployParams.deployerContract = address(
                0xEFb8369Fb33bA67832B7120C94698e5372eE61C3
            );
        } else {
            revert("PARAMS_NOT_SET");
        }
    }
}
