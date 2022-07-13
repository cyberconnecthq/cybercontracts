[![test](https://github.com/cyberconnecthq/cybercontracts/actions/workflows/test.yml/badge.svg)](https://github.com/cyberconnecthq/cybercontracts/actions/workflows/test.yml)

# CyberConnect Contracts

This hosts all contracts for CyberConnect's social graph protocol.

Some opinionated design decisino:

1. Prefer `require` for semantic clearity.
2. No custom error until `require` supports custom error.
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

# Set Up

0. Upgrade your foundry
   `foundryup`

1. To enable husky pre-commit
   `yarn && yarn prepare`

2. To install contract dependencies
   `forge install`

3. To build
   `forge build`

4. To test
   `forge test -vvv`

5. (optional) To run static analysis
   `slither src/`

6. To see contract sizes
   `yarn size`

# Deployment:

(Replace `rinkeby` with `anvil` or other supported network) 0. Create `.env.rinkeby` file with following env

```bash
RINKEBY_RPC_URL=
PRIVATE_KEY=
ETHERSCAN_KEY=
PINATA_JWT=
```

for local deployment in `.env.anvil`

```bash
PRIVATE_KEY=
PINATA_JWT=
```

1. Run `yarn pre_deploy` to prepare animation url pinata link that is used to deploy. Take note of the `profile proxy` address, which will be used later.

2. Run `yarn deploy:rinkeby` or `yarn deploy:anvil` for local deployment. If you run into any unconfirmed txs, run `yarn deploy:rinkeby --resume` to continue. This also verifies contract on etherscan. Check `profile proxy` address log to make sure it's the same as step 0. Otherwise, abort. (This manual step will be fixed)

3. Run `yarn post_deploy` to update contract addresses and ABI changes

# Tests

[QRCode](./docs/test/qrcode.md)

# Interaction

To interact with the protocol, directly call functions on CyberEngine.

## Register

Register Fee based on handle length
| Length | Fee (ETH) |
|--------|-----------|
| 1 | 10 |
| 2 | 2 |
| 3 | 1 |
| 4 | 0.5 |
| 5 | 0.1 |
| >=6 | 0.01 |

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

# License

GNU General Public License v3.0 or later

See [COPYING](./COPYING) to see the full text.

# TODO

- verify profile contracts deployed from engine
