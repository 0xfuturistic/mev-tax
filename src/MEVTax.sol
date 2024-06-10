// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @notice Error to be used when the paid amount is not enough to cover the tax.
error NotEnoughPaid();

/// @title MEVTax
/// @notice This contract should be inherited by contracts to apply a MEV tax.
///         The tax amount is calculated as a function of the priority fee per
///         gas of the transaction. Solvers pay the tax in anticipation of the
///         function call that applies the tax.
contract MEVTax {
    /// @notice Amount paid to cover taxes but not yet used (in wei)
    uint256 internal _paidAmount;

    /// @notice Modifier to apply tax on function calls
    modifier applyTax() {
        _applyTax();
        _;
    }

    /// @notice Pays tax in anticipation of a function call that applies tax
    ///         This function should be called by the solver to pay the tax
    ///         before calling the function that applies tax.
    function payTax() external payable virtual {
        _paidAmount += msg.value;
    }

    /// @notice Checks if the paid amount is sufficient to cover the tax.
    function _applyTax() internal {
        uint256 taxAmount = _getTaxAmount();
        if (_paidAmount < taxAmount) {
            revert NotEnoughPaid();
        }
        _paidAmount -= taxAmount;
    }

    /// @notice Returns the tax amount as a function of the priority fee per gas
    ///         of the transaction. Should be overridden to customize tax function.
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
