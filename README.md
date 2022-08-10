[![test](https://github.com/cyberconnecthq/cybercontracts/actions/workflows/test.yml/badge.svg)](https://github.com/cyberconnecthq/cybercontracts/actions/workflows/test.yml)
<a href="https://codecov.io/gh/cyberconnecthq/cybercontracts" > 
   <img src="https://codecov.io/gh/cyberconnecthq/cybercontracts/branch/main/graph/badge.svg?token=QKX1FYTBFM"/>
</a>
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
# .env.pinata
PINATA_JWT=
```

```bash
# .env.rinkeby
RINKEBY_RPC_URL=
PRIVATE_KEY=
ETHERSCAN_KEY=
```

for local deployment in `.env.anvil`

```bash
# .env.anvil
PRIVATE_KEY=
PINATA_JWT=
```

0. You need a `Create2Deployer` to start the deployment. If you don't have a contract address, run `yarn deploy_deployer:goerli` or change deployerContract address in `Deploy.s.sol` to 0 to let the script deploy. Take down the deployer contract address
1. Run `yarn deploy:goerli` or `yarn deploy:anvil` for local deployment. If you run into any unconfirmed txs, run `yarn deploy:rinkeby --resume` to continue. This also verifies contract on etherscan. Check `profile proxy` address log to make sure it's the same as step 0. Otherwise, abort. (This manual step will be fixed)
2. Run `yarn post_deploy` to update ABI changes
3. Run `yarn upload_animation:goerli` to upload animation uri for link3 to ipfs.
4. Check `DeploySetting.sol` and make sure the deployer contract is correctly set as shown in `docs/deploy/<network>/contract.md`. Run `yarn set_animation_url:goerli` to deploy link3 nft descriptor with animation url. Then set to profile.

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
