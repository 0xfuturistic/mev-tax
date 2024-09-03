// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MEVTaxBase, MevTaxLib} from "src/library/MevTaxLib.sol";

/// @title  MEVTax
/// @notice This contract should be inherited by contracts to apply a MEV tax.
///         The tax amount is calculated as a function of the priority fee per
///         gas of the transaction.
/// @dev    This contract uses transient storage to store the delta for msg.value.
contract MEVTax is MEVTaxBase {
    /// @notice inherits from MEVTaxBase
    /// @return output of the tax function (the tax amount for _priorityFeePerGas).
    function getTaxAmount() internal view virtual override returns (uint256) {
        return tax(_currentPriorityFeePerGas());
    }

    /// @notice Returns the current priority fee per gas.
    /// @return Priority fee per gas.
    function _currentPriorityFeePerGas() internal view returns (uint256) {
        return tx.gasprice - block.basefee;
    }

    /// @notice Computes the tax function for a _priorityFeePerGas.
    ///         Unless overridden, it is 99 times the priority fee per gas.
    /// @dev    Override this function to implement a custom tax function.
    /// @param  _priorityFeePerGas Priority fee per gas to input to the tax function.
    /// @return Output of the tax function (the tax amount for _priorityFeePerGas).
    function tax(uint256 _priorityFeePerGas) public view virtual returns (uint256) {
        return 99 * _priorityFeePerGas;
    }
}
