[![test](https://github.com/cyberconnecthq/cybercontracts/actions/workflows/test.yml/badge.svg)](https://github.com/cyberconnecthq/cybercontracts/actions/workflows/test.yml)

# CyberConnect Contracts

This hosts all contracts for CyberConnect's social graph protocol.

Some opinions:

1. Prefer require for semantic clearity.
2. No custom error until require supports custom error.
3. NFTs don't support burn
4. Try to be gas efficient :)

# Dependencies

[Foundry](https://github.com/foundry-rs/foundry) ([book](https://book.getfoundry.sh/))
[slither](https://github.com/crytic/slither)

# Live Deployment

## Rinkeby

[Deployment](./docs/deploy/rinkeby.md)

# ABI

[ABI](./docs/abi/README.md)

# Usage

0. Upgrade your foundry
`foundryup`

1. To enable husky pre-commit
`yarn add --dev husky & yarn prepare`

2. To install contract dependencies
`forge install`

3. To build
`forge build`

4. To test
`forge test -vvv`

5. (optional) To run static analysis
`slither src/`

# Deployment:

(Replace `rinkeby` with `anvil` or other supported network) 0. Create `.env.rinkeby` file with following env

```bash
RINKEBY_RPC_URL=<Your Rinkeby RPC endpoint>
PRIVATE_KEY=<Your wallets private key>
ETHERSCAN_KEY=<Your Etherscan API key>
```

for local deployment

```bash
PRIVATE_KEY=
```

1. Run `yarn deploy:rinkeby` or `yarn deploy:anvil` for local deployment. If you run into any unconfirmed txs, run `yarn deploy:rinkeby --resume` to continue. This also verifies contract on etherscan

2. Run `yarn post_deploy` to update contract addresses and ABI changes

# Interaction

To interact with the protocol, directly call functions on CyberEngine.

## Register

Register Fee based on handle length
| Length | Fee (ETH) |
|--------|-----------|
| 2      | 0.5       |
| 3      | 0.1       |
| 4      | 0.06      |
| 5      | 0.03      |
| 6      | 0.01      |
| >=7    | 0.006     |

# MAYBE TODO's
- [ ] SVG generation
- [ ] SBT NFT
- [ ] SBT Module
- [ ] Permit with EIP712
- [ ] Crosschain support (openzeppelin contract) (https://docs.openzeppelin.com/contracts/4.x/api/crosschain)
- [ ] Reserve slots for EssenceNFT
- [ ] Put BoxNFT into peripheral
- [ ] Include chainID in SubscribeNFT, EssenceNFT
- [ ] Token URI
- [ ] fix slither
- [ ] fix solhint
- [ ] documentation style
```
