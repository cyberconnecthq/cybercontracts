[![test](https://github.com/cyberconnecthq/cybercontracts/actions/workflows/test.yml/badge.svg)](https://github.com/cyberconnecthq/cybercontracts/actions/workflows/test.yml)

<a href="https://codecov.io/gh/cyberconnecthq/cybercontracts" > 
   <img src="https://codecov.io/gh/cyberconnecthq/cybercontracts/branch/main/graph/badge.svg?token=QKX1FYTBFM"/>
</a>

# CyberConnect Contracts

This hosts all contracts for CyberConnect's social graph protocol.

Some opinionated design decisino:

1. Prefer `require` for semantic clearity.
2. No custom error until `require` supports custom error.
3. Try to be gas efficient :)

# Dependencies

[Foundry](https://github.com/foundry-rs/foundry) ([book](https://book.getfoundry.sh/))
[slither](https://github.com/crytic/slither)

# ABI

[ABI](./docs/abi/)

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

0. Deploy `Actions` first with `npx hardhat run --network goerli hardhat-scripts/deployActions.ts`
1. You need a `Create2Deployer` to start the deployment. If you don't have a contract address, run `yarn deploy_deployer:goerli` or change deployerContract address in `Deploy.s.sol` to 0 to let the script deploy. Take down the deployer contract address
2. Run `yarn deploy:goerli` or `yarn deploy:anvil` for local deployment. If you run into any unconfirmed txs, run `yarn deploy:rinkeby --resume` to continue. This also verifies contract on etherscan. Check `profile proxy` address log to make sure it's the same as step 0. Otherwise, abort. (This manual step will be fixed)
3. Run `yarn post_deploy` to update ABI changes
4. Run `yarn upload_animation:goerli` to upload animation uri for link3 to ipfs.
5. Check `DeploySetting.sol` and make sure the deployer contract is correctly set as shown in `docs/deploy/<network>/contract.md`. Run `yarn set_animation_url:goerli` to deploy link3 nft descriptor with animation url. Then set to profile.

# Verify on Etherscan

Because we use `create2` for deployments, so we need to manually submit verification.

1. Verify `CyberEngineImpl`

```
forge verify-contract --chain-id 5 --num-of-optimizations 200 <address> src/core/CyberEngine.sol:CyberEngine  $ETHERSCAN_KEY
```

2. Verify `CyberEngineProxy`

a. find the `init_data`

```
bytes memory data = abi.encodeWithSelector(
   CyberEngine.initialize.selector,
   address(0),
   authority
);
console.logBytes(data);
```

b. verify

```
forge verify-contract --chain-id 5 --num-of-optimizations 200 <address> lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy --constructor-args $(cast abi-encode "constructor(address,bytes)" <impl_address> <init_data>)  $ETHERSCAN_KEY
```

3. Verify `Profile`

# Tests

[QRCode](./docs/test/qrcode.md)

# License

GNU General Public License v3.0 or later

See [COPYING](./COPYING) to see the full text.
