# 🩸 MEV-Tax: A Solidity Library for MEV Taxes

MEV-Tax provides a simple way for developers to incorporate [MEV taxes](https://www.paradigm.xyz/2024/06/priority-is-all-you-need) into their contracts, enabling them to automatically capture MEV based on the priority fee.

## Features

- Easy integration with existing smart contracts
- Tax calculation based on transaction priority fee
- Customizable tax recipient
- Enables various use cases for MEV mitigation (e.g., DEX routers, AMMs, backrunning auctions)

## How it Works

Background: [Priority Is All You Need](https://www.paradigm.xyz/2024/06/priority-is-all-you-need) by Dan Robinson and Dave White (Paradigm).

The library calculates a tax amount based on the priority fee per gas of the transaction. When a function with the `applyTax()` modifier is called, the library tries to transfer a sufficient amount of an ERC20 currency to cover the tax. If that succeeds, the transaction proceeds. Otherwise, the transaction reverts.

## Getting Started

1. Install the library in your Solidity project
```bash
forge install 0xfuturistic/mev-tax
```
2. Import and inherit `MEVTax` in your smart contract
```solidity
import {MEVTax} from "mev-tax/src/MEVTax.sol";
```
3. Add `MEVTax` to your constructor
```solidity
constructor() MEVTax(currencyAddress) {}
```
replacing `currencyAddress` by the address of the ERC20 token for paying the MEV tax.
The implementation works especially well when this is the address of WETH in the network. 
For other tokens, an exchange rate from eth may be needed to compute the tax accurately.

4. Apply the `applyTax()` modifier to functions where you want to capture MEV

Whoever pays for the tax must have enough amount of `currencyAddress` to cover the tax and to have approved at least that amount for the contract. 

5. Optionally, override the `_getTaxAmount()` function for a custom tax function

## Limitations

The library relies on the assumption of competitive priority ordering, which means it only works for L2s like Base and Optimism, where there's a trusted sequencer, but not for Ethereum Mainnet. Enforcing these rules trustlessly is an open problem.

## Contribute & Feedback

Feel free to raise an issue, suggest a feature, or even fork the repository for personal tweaks. If you'd like to contribute, please fork the repository and make changes as you'd like. Pull requests are warmly welcome.

For questions and feedback, you can also reach out via [Twitter](https://twitter.com/0xfuturistic).
