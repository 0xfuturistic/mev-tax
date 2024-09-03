// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

/// @title MEVTaxLegacyBase
abstract contract MEVTaxLegacyBase is Ownable {
    /// @notice Thrown when the value of the transaction is insufficient.
    error InsufficientMsgValue();

    /// @notice Thrown when the magnitude of the negative delta to account for
    ///         subtractions to msg.value is greater than msg.value.
    error DeltaAdjustedMsgValueUnderflow();

    /// @notice Slot for the delta to account for updates to msg.value.
    bytes32 public constant MSG_VALUE_DELTA_SLOT = keccak256("MEVTax._msgValueDelta");

    /// @notice Currency for paying the tax in native ether.
    address public constant ETH_CURRENCY = address(0);

    /// @notice Currency for paying the tax.
    address public currency = ETH_CURRENCY;

    /// @notice Recipient of the tax transfers.
    address public recipient = address(this);

    /// @notice Modifier to apply tax on a function.
    ///         If applying the tax fails, the modifier reverts.
    modifier applyTax() virtual {
        _applyTax();
        _;
        _afterApplyTax();
    }

    /// @dev Sets the deployer as the initial owner.
    constructor() Ownable(msg.sender) {}

    /// @notice Sets the currency to _currency.
    /// @param _currency Address of the currency to set.
    function setCurrency(address _currency) external onlyOwner {
        currency = _currency;
    }

    /// @notice Sets the recipient to _recipient.
    /// @param _recipient Address of the recipient to set.
    function setRecipient(address _recipient) external onlyOwner {
        recipient = _recipient;
    }

    /// @notice Returns whether the currency is native ether.
    /// @return True if the currency is native ether, and false otherwise.
    function isCurrencyETH() public view returns (bool) {
        return currency == ETH_CURRENCY;
    }

    /// @notice Computes the tax function for a _priorityFeePerGas.
    ///         Unless overridden, it is 99 times the priority fee per gas.
    /// @dev    Override this function to implement a custom tax function.
    /// @param  _priorityFeePerGas Priority fee per gas to input to the tax function.
    /// @return Output of the tax function (the tax amount for _priorityFeePerGas).
    function tax(uint256 _priorityFeePerGas) public view virtual returns (uint256) {
        return 99 * _priorityFeePerGas;
    }

    /// @notice Applies tax at the transaction's priority fee per gas.
    ///         If the transfer fails, the function reverts.
    function _applyTax() internal {
        uint256 taxAmount = tax(_currentPriorityFeePerGas());

        if (isCurrencyETH()) {
            if (_msgValue() < taxAmount) revert InsufficientMsgValue();
            // subtract the tax amount from the delta
            _updateMsgValueDelta(taxAmount);
            // transfer the tax amount
            SafeTransferLib.safeTransferETH(recipient, taxAmount);
        } else {
            // transfer the tax amount
            // if the allowance or balance are insufficient, the transfer will automatically revert
            SafeTransferLib.safeTransferFrom(currency, msg.sender, recipient, taxAmount);
        }
    }

    /// @notice After applying the tax, performs any necessary cleanup.
    function _afterApplyTax() internal virtual {}

    /// @notice Returns the current priority fee per gas.
    /// @return Priority fee per gas.
    function _currentPriorityFeePerGas() internal view returns (uint256) {
        return tx.gasprice - block.basefee;
    }

    /// @notice Returns the dynamic value of the transaction, accounting for
    ///         subtractions to msg.value.
    /// @return Delta-adjusted value of the transaction.
    function _msgValue() internal view virtual returns (uint256) {
        uint256 delta = _msgValueDelta();
        if (msg.value < delta) revert DeltaAdjustedMsgValueUnderflow();
        return msg.value - delta;
    }

    /// @notice Returns the magnitude of the negative delta to account for
    ///         subtractions to msg.value.
    function _msgValueDelta() internal view virtual returns (uint256);

    /// @notice Updates the magnitude of the negative delta to account for
    ///         a change in msg.value.
    function _updateMsgValueDelta(uint256 _delta) internal virtual;
}
