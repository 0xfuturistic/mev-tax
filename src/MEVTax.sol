// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title MEVTax
/// @notice This contract should be inherited by contracts to apply a MEV tax.
///         The tax amount is calculated as a function of the priority fee per
///         gas of the transaction.
contract MEVTax is Ownable {
    /// @notice The currency used to pay the tax.
    address public currency;

    /// @notice The recipient of the tax payments.
    address public recipient = address(this);

    /// @notice Modifier to apply tax on a function. If the paid amount (msg.value)
    ///         is not enough to cover the tax, the modifier reverts.
    modifier applyTax() {
        _;
        _payTax();
    }

    /// @notice Sets the deployer as the initial owner.
    constructor() Ownable(msg.sender) {}

    /// @notice Sets the currency used to pay the tax.
    /// @param _currency The new currency used to pay the tax.
    function setCurrency(address _currency) external onlyOwner {
        // TODO: enforce that the address is a valid ERC20 receiver
        currency = _currency;
    }

    /// @notice Sets the recipient of the tax payments.
    /// @param _recipient The new recipient of the tax payments.
    function setRecipient(address _recipient) external onlyOwner {
        recipient = _recipient;
    }

    /// @notice Applies tax if the paid amount is sufficient to cover the tax.
    ///         Otherwise, the function reverts.
    function _payTax() internal {
        IERC20(currency).transferFrom(msg.sender, recipient, _getTaxAmount());
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
