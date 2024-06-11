# 🩸 MEV-Tax: A Solidity Library for MEV Taxes

MEV-Tax provides a simple way for developers to incorporate [MEV taxes](https://www.paradigm.xyz/2024/06/priority-is-all-you-need) into their contracts, enabling the contracts to automatically capture MEV.

## Features

- Easy integration with existing smart contracts
- Robust tax calculation based on transaction priority fee
- Customizable tax recipient
- Enables various use cases for MEV mitigation (e.g., DEX routers, AMMs, backrunning auctions)

## How it Works

Background: [Priority Is All You Need](https://www.paradigm.xyz/2024/06/priority-is-all-you-need) by Paradigm.


The library calculates a tax amount based on the priority fee per gas of the transaction. When a function with the `applyTax()` modifier is called, the library checks if the paid amount (`msg.value`) is sufficient to cover the tax. If so, the transaction proceeds, and the tax is transferred to the designated recipient. Otherwise, the transaction reverts.

## Getting Started

1. Install the library in your Solidity project
```bash
forge install 0xfuturistic/mev-tax
```
2. Import and inherit `MEVTax.sol` in your smart contract
```solidity
import "mev-tax/src/MEVTax.sol";
```
3. Apply the `applyTax()` modifier to functions where you want to capture MEV
4. Optionally, override the `_getTaxAmount()` function for a custom tax function

## Limitations

The library relies on the assumption of competitive priority ordering, which means it only works for L2s like Base and Optimism, where there's a trusted sequencer, but not for Ethereum Mainnet. Enforcing these rules trustlessly is an open problem.

## Contribute & Feedback

Feel free to raise an issue, suggest a feature, or even fork the repository for personal tweaks. If you'd like to contribute, please fork the repository and make changes as you'd like. Pull requests are warmly welcome.

For questions and feedback, you can also reach out via [Twitter](https://twitter.com/0xfuturistic).
