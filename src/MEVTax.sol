// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MEVTaxBase} from "src/MEVTaxBase.sol";
import {TransientContext} from "transience/TransientContext.sol";

/// @title  MEVTax
/// @notice This contract should be inherited by contracts to apply a MEV tax.
///         The tax amount is calculated as a function of the priority fee per
///         gas of the transaction.
/// @dev    This contract uses transient storage to store the delta for msg.value.
contract MEVTax is MEVTaxBase {
    /// @dev Slot for the delta to account for updates to msg.value.
    bytes32 public constant MSG_VALUE_DELTA_SLOT = keccak256("MEVTax._msgValueDelta");

    modifier applyTax() override {
        _applyTax();
        _;
    }

    /// @notice Returns the delta to account for a change in msg.value.
    function _msgValueDelta() internal view override returns (uint256) {
        return TransientContext.get(MSG_VALUE_DELTA_SLOT);
    }

    /// @notice Updates the delta to account for a change in msg.value.
    function _updateMsgValueDelta(uint256 _delta) internal override {
        TransientContext.set(MSG_VALUE_DELTA_SLOT, _msgValueDelta() + _delta);
    }
}
