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

    uint256 internal constant ANVIL = 31337;
    uint256 internal constant GOERLI = 5;
    uint256 internal constant BNBT = 97;
    uint256 internal constant BNB = 56;
    uint256 internal constant RINKEBY = 4;
    uint256 internal constant MAINNET = 1;
    uint256 internal constant NOVA = 42170;
    uint256 internal constant POLYGON = 137;

    function _setDeployParams() internal {
        // Anvil accounts
        // (0) 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 (10000 ETH)
        // (1) 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 (10000 ETH)
        // (2) 0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc (10000 ETH)

        // Testnet accounts
        // deployer: 0x927f355117721e0E8A7b5eA20002b65B8a551890
        // engine treasury: 0x1890a1625d837A809b0e77EdE1a999a161df085d
        // link3 treasury + signer: 0xaB24749c622AF8FC567CA2b4d3EC53019F83dB8F
        if (block.chainid == ANVIL) {
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
        } else if (
            block.chainid == GOERLI ||
            block.chainid == RINKEBY ||
            block.chainid == BNBT
        ) {
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
            deployParams.deployerContract = address(
                0x4077B8554A5F9A3C2D10c6Bb467B7E26Caf65ad9
            );
        } else if (
            block.chainid == MAINNET ||
            block.chainid == NOVA ||
            block.chainid == BNB ||
            block.chainid == POLYGON
        ) {
            deployParams.link3Owner = address(
                0x39e0c6E610A8D7F408dD688011591583cbc1c3ce
            );
            deployParams.link3Signer = address(
                0x2A2EA826102c067ECE82Bc6E2B7cf38D7EbB1B82
            );
            deployParams.link3Treasury = address(
                0xf9E12df9428F1a15BC6CfD4092ADdD683738cE96
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
                0x9aEd1dA7127bF39838f6a1F407563437b362C64f
            );
            deployParams.deployerContract = address(
                0xEFb8369Fb33bA67832B7120C94698e5372eE61C3
            );
        } else {
            revert("PARAMS_NOT_SET");
        }
    }
}
