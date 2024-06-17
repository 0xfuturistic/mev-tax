// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

/// @title MEVTax
/// @notice This contract should be inherited by contracts to apply a MEV tax.
///         The tax amount is calculated as a function of the priority fee per
///         gas of the transaction.
contract MEVTax is Ownable {
    /// @notice Thrown when the value of the transaction is insufficient.
    error InsufficientMsgValue();

    /// @notice Currency for paying the tax in native ether.
    address public constant ETH_CURRENCY = address(0);

    /// @notice Currency for paying the tax.
    address public currency = ETH_CURRENCY;

    /// @notice Recipient of the tax transfers.
    address public recipient = address(this);

    /// @dev Delta to account for updates to msg.value.
    int256 internal _msgValueDelta = 0;

    /// @notice Modifier to apply tax on a function.
    ///         If applying the tax fails, the modifier reverts.
    modifier applyTax() {
        _applyTax();
        _;
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
        uint256 taxAmount = tax(_getPriorityFeePerGas());

        if (isCurrencyETH()) {
            if (_msgValue() < taxAmount) revert InsufficientMsgValue();
            _msgValueDelta -= int256(taxAmount);
            SafeTransferLib.safeTransferETH(recipient, taxAmount);
        } else {
            SafeTransferLib.safeTransferFrom(currency, msg.sender, recipient, taxAmount);
        }
    }

    /// @notice Returns the priority fee per gas.
    /// @return Priority fee per gas.
    function _getPriorityFeePerGas() internal view returns (uint256) {
        return tx.gasprice - block.basefee;
    }

    /// @notice Returns the dynamic value of the transaction, accounting for a delta.
    /// @return Delta-adjusted value of the transaction.
    function _msgValue() internal view virtual returns (uint256) {
        require(
            !(_msgValueDelta < 0 && msg.value < uint256(-1 * _msgValueDelta)),
            "MEVTax: delta-adjusted msg.value underflow"
        );
        return uint256(int256(msg.value) + _msgValueDelta);
    }
}
