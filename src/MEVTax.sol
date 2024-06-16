// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Currency, CurrencyLibrary} from "src/Currency.sol";

/// @title MEVTax
/// @notice This contract should be inherited by contracts to apply a MEV tax.
///         The tax amount is calculated as a function of the priority fee per
///         gas of the transaction.
contract MEVTax is Ownable {
    error InsufficientValue();

    /// @notice Currency for paying the tax.

    Currency public currency;

    /// @notice Recipient of the tax transfers.
    address public recipient = address(this);

    uint256 internal _negDelta = 0;

    /// @notice Modifier to apply tax on a function.
    ///         If applying the tax fails, the modifier reverts.
    modifier applyTax() {
        _applyTax();
        _;
    }

    /// @dev Sets the deployer as the initial owner.
    constructor() Ownable(msg.sender) {
        currency = CurrencyLibrary.NATIVE;
    }

    /// @notice Updates currency to _currency.
    /// @param _currency ERC20 token setting _currency to.
    function setCurrency(Currency _currency) external onlyOwner {
        currency = _currency;
    }

    /// @notice Updates recipient to _recipient.
    /// @param _recipient Address setting recipient to.
    function setRecipient(address _recipient) external onlyOwner {
        recipient = _recipient;
    }

    /// @notice Computes the tax function for an arbitrary _priorityFeePerGas.
    ///         Unless overridden, it is 99 times the priority fee per gas.
    /// @dev    Override this function to implement an arbitrary tax function.
    /// @param  _priorityFeePerGas Priority fee per gas to input to the tax function.
    /// @return Output of the tax function (the tax amount for _priorityFeePerGas).
    function tax(uint256 _priorityFeePerGas) public view virtual returns (uint256) {
        return 99 * _priorityFeePerGas;
    }

    /// @notice Applies tax by transferring the tax amount (at the tx's priority fee per gas)
    ///         from msg.sender to recipient. If the transfer fails, _payTax reverts.
    function _applyTax() internal {
        uint256 taxAmount = tax(_getPriorityFeePerGas());

        if (currency.isNative()) {
            if (_msgValue() < taxAmount) revert InsufficientValue();
            _negDelta += taxAmount;
        }

        currency.transferFrom(msg.sender, recipient, taxAmount);
    }

    /// @notice Returns the priority fee per gas.
    /// @return Priority fee per gas.
    function _getPriorityFeePerGas() internal view returns (uint256) {
        return tx.gasprice - block.basefee;
    }

    /// @notice Returns the dynamic value of the transaction, accounting for a negative delta
    //          The negative delta is used to account for the tax amount in the transaction value.
    /// @return Negative delta-adjusted value of the transaction.
    function _msgValue() internal view virtual returns (uint256) {
        return msg.value - _negDelta;
    }
}
