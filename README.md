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


# Usage
To enable husky pre-commit
`yarn add --dev husky & yarn prepre`

To install contract dependencies
`forge install`

To build
`forge build`

To test
`forge test -vvv`

To run static analysis
`slither .`

# Deployment:

Set the following environment variables

```bash
RPC_URL=<Your RPC endpoint>
PRIVATE_KEY=<Your wallets private key>
```

to deploy
`npm run deploy <args>`

# TODO
- [x] BaseNFT
- [x] Validate handle (lower-case alphabetical, numerical, _)
- [ ] Governance, Pausable
- [ ] Mint with Signature
- [ ] SVG generation
- [ ] Purchase logic
- [ ] SBT NFT
- [ ] SBT Module
- [x] Onchain Token URI
- [ ] Permit with EIP712
- [ ] Upgradeable and Proxy (UUPS)
- [ ] Crosschain support (openzeppelin contract) (https://docs.openzeppelin.com/contracts/4.x/api/crosschain)
- [ ] Events
- [ ] BoxNFT

- [x] Hardhat plugin, add license
- [x] linter
- [ ] fix slither
- [ ] fix solhint