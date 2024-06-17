// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {MEVTaxBase} from "src/MEVTaxBase.sol";
import {Storage} from "optimism/libraries/Storage.sol";

/// @title MEVTax
/// @notice This contract should be inherited by contracts to apply a MEV tax.
///         The tax amount is calculated as a function of the priority fee per
///         gas of the transaction.
contract MEVTax is MEVTaxBase {
    /// @dev Slot for the delta to account for updates to msg.value.
    bytes32 internal constant _MSG_VALUE_DELTA_SLOT = keccak256("MEVTax._msgValueDelta");

    /// @notice Returns the delta to account for a change in msg.value.
    function _msgValueDelta() internal view override returns (uint256) {
        return Storage.getUint(_MSG_VALUE_DELTA_SLOT);
    }

    /// @notice Updates the delta to account for a change in msg.value.
    function _updateMsgValueDelta(uint256 _delta) internal override {
        Storage.setUint(_MSG_VALUE_DELTA_SLOT, _delta);
    }
}
