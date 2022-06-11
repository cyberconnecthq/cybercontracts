# CyberConnect Contracts

This hosts all contracts for CyberConnect's social graph protocol.

Some opinions:
1. Prefer require for semantic clearity. 
2. No custom error until require supports custom error.
3. NFTs don't support burn
4. Try to be gas efficient :)


# Dependencies

[Foundry](https://github.com/foundry-rs/foundry) ([book](https://book.getfoundry.sh/))


# Usage

To build
`forge build`

To test
`forge test`

# TODO
- [ ] BaseNFT
- [ ] Validate handle
- [ ] Profile NFT
- [ ] SVG generation
- [ ] Purchase logic
- [ ] SBT NFT
- [ ] SBT Module
- [x] Onchain Token URI
- [ ] Permit with EIP712
- [ ] Upgradeable and Proxy
- [ ] Emergency upgrade and pausability
- [ ] Crosschain support (openzeppelin contract)

- [ ] Hardhat plugin, add license
- [ ] linter