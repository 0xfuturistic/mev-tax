// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title MEV Tax contract
/// @notice This contract is to be inherited from to access modifier for
///         applying a priority-fee based tax on function calls.
contract MEVTax {
    /// @notice Amount of ETH paid for tax but not yet used
    uint256 internal _paidAmount;

    /// @notice Modifier to apply tax on function calls
    modifier applyTax() {
        _checkTaxPayment();
        _;
    }

    /// @notice Pays tax in anticipation of a function call that applies tax
    ///         This function should be called by the solver to pay the tax
    ///         before calling the function that applies tax.
    function payTax() external payable virtual {
        _paidAmount += msg.value;
    }

    /// @notice Checks if the paid amount is sufficient to cover the tax.
    function _checkTaxPayment() internal {
        uint256 taxAmount = _getTaxAmount();
        if (_paidAmount < taxAmount) {
            revert("NotEnoughPaid()");
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
