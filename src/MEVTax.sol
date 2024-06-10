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
    /// @notice Amount paid for covering taxes but not used so far.
    uint256 internal _paidAmount;

    /// @notice Applies tax before an arbitrary function. If the paid amount is
    ///         not enough to cover the tax, the modifier reverts.
    modifier applyTax() {
        _applyTax();
        _;
    }

    /// @notice Used to pay tax amount for a future function call that applies tax.
    ///         This function should be called by the solver to pay the tax
    ///         before the user's transaction.
    function payTax() external payable virtual {
        _paidAmount += msg.value;
    }

    /// @notice Applies tax if the paid amount is sufficient to cover the tax.
    ///         Otherwise, the function reverts.
    function _applyTax() internal {
        uint256 taxAmount = _getTaxAmount();
        if (_paidAmount < taxAmount) {
            revert NotEnoughPaid();
        }
        _paidAmount -= taxAmount;
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
