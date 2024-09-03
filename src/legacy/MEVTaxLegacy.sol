// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {MEVTaxLegacyBase} from "src/legacy/MEVTaxLegacyBase.sol";
import {Storage} from "optimism/libraries/Storage.sol";

/// @title  MEVTaxLegacy
/// @notice This contract should be inherited by contracts to apply a MEV tax.
///         The tax amount is calculated as a function of the priority fee per
///         gas of the transaction.
/// @dev    This contract uses regular storage to store the delta for msg.value.
contract MEVTaxLegacy is MEVTaxLegacyBase {
    /// @notice Returns the magnitude of the negative delta to account for
    ///         subtractions to msg.value.
    function _msgValueDelta() internal view override returns (uint256) {
        return Storage.getUint(MSG_VALUE_DELTA_SLOT);
    }

    /// @notice Updates the magnitude of the negative delta to account for
    ///         a change in msg.value.
    function _updateMsgValueDelta(uint256 _delta) internal override {
        Storage.setUint(MSG_VALUE_DELTA_SLOT, _msgValueDelta() + _delta);
    }

    /// @notice After applying the tax, resets the slot to zero.
    function _afterApplyTax() internal override {
        Storage.setUint(MSG_VALUE_DELTA_SLOT, 0);
    }
}
