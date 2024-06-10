// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @notice Error to be used when the paid amount is not enough to cover the tax.
error NotEnoughPaid();

/// @title MEVTax
/// @notice This contract should be inherited by contracts to apply a MEV tax.
///         The tax amount is calculated as a function of the priority fee per
///         gas of the transaction. Solvers (or whomever) pay the tax amount
///         in anticipation of the function call that applies the tax.
contract MEVTax {
    address payable public recipient;

    /// @notice Applies tax before an arbitrary function. If the paid amount is
    ///         not enough to cover the tax, the modifier reverts.
    modifier applyTax() {
        _;
        _payTax();
    }

    /// @notice Applies tax if the paid amount is sufficient to cover the tax.
    ///         Otherwise, the function reverts.
    function _payTax() internal {
        uint256 taxAmount = _getTaxAmount();
        if (msg.value < taxAmount) {
            revert NotEnoughPaid();
        }
        recipient.transfer(taxAmount);
    }

    /// @notice Returns the tax amount, which is defined as a function of the
    ///         priority fee per gas of the transaction.
    /// @dev    This function should be overriden to implement custom tax function.
    /// @return The tax amount as a function of the priority fee per gas.
    function _getTaxAmount() internal view virtual returns (uint256) {
        return _getPriorityFeePerGas() * 99;
    }

    /// @notice Returns the priority fee per gas of the transaction.
    /// @return The priority fee per gas of the transaction.
    function _getPriorityFeePerGas() internal view returns (uint256) {
        return tx.gasprice - block.basefee;
    }
}
