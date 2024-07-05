// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {TransientContext} from "transience/TransientContext.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

library MevTaxLib {
    /// @notice Slot for the delta to account for updates to msg.value.
    bytes32 public constant MSG_VALUE_DELTA_SLOT = keccak256("MEVTax._msgValueDelta");
    /// @notice Currency for paying the tax in native ether.
    address public constant ETH_CURRENCY = address(0);
    
    /// @notice Transfers the tax amount in native ether or ERC20 to the recipient.
    function transferTax(address currency, address from, address recipient, uint256 taxAmount) internal {
        if (currency == ETH_CURRENCY) {
            SafeTransferLib.safeTransferETH(recipient, taxAmount);
            _updateMsgValueDelta(getMsgValueDelta() + taxAmount);
        } else {
            SafeTransferLib.safeTransferFrom(currency, from, recipient, taxAmount);
        }
    }

    /// @notice Updates the magnitude of the negative delta to account for
    ///         a change in msg.value.
    function _updateMsgValueDelta(uint256 delta) internal {
        TransientContext.set(MSG_VALUE_DELTA_SLOT, delta);
    }

    /// @notice Returns the magnitude of the negative delta to account for
    ///         subtractions to msg.value.
    function getMsgValueDelta() internal view returns (uint256) {
        return TransientContext.get(MSG_VALUE_DELTA_SLOT);
    }
}

abstract contract MEVTaxBase is Ownable {
    /// @notice Thrown when the value of the transaction is insufficient.
    error InsufficientMsgValue();

    /// @notice Thrown when the magnitude of the negative delta to account for
    ///         subtractions to msg.value is greater than msg.value.
    error DeltaAdjustedMsgValueUnderflow();

    /// @notice Currency for paying the tax.
    address public currency = MevTaxLib.ETH_CURRENCY;

    /// @notice Recipient of the tax transfers.
    address public recipient = address(this);

    /// @notice Modifier to apply tax on a function.
    ///         If applying the tax fails, the modifier reverts.
    modifier applyTax() virtual{
        _applyTax();
        _;
    }

    /// @notice Applies tax at the transaction's priority fee per gas.
    ///         If the transfer fails, the function reverts.
    function _applyTax() internal {
        uint256 taxAmount = getTaxAmount();
        if (isCurrencyETH() && _msgValue() < taxAmount) {
            revert InsufficientMsgValue();
        }
        MevTaxLib.transferTax(currency, msg.sender, recipient, taxAmount);
    }

    /// @dev Sets the deployer as the initial owner.
    constructor() Ownable(msg.sender) {}

    /// @notice Returns whether the currency is native ether.
    /// @return True if the currency is native ether, and false otherwise.
    function isCurrencyETH() public view returns (bool) {
        return currency == MevTaxLib.ETH_CURRENCY;
    }

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

    /// @notice Returns the dynamic value of the transaction, accounting for
    ///         subtractions to msg.value.
    /// @return Delta-adjusted value of the transaction.
    function _msgValue() internal view virtual returns (uint256) {
        uint256 delta = MevTaxLib.getMsgValueDelta();
        if (msg.value < delta) revert DeltaAdjustedMsgValueUnderflow();
        return msg.value - delta;
    }

    /// @notice Returns the tax amount for the transaction.
    function getTaxAmount() internal view virtual returns (uint256);
}
