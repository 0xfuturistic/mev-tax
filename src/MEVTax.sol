// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MEVTax {
    bytes32 internal TAXED_SLOT = keccak256("MEVTax.taxed");

    uint256 internal _paidAmount;

    modifier tax() {
        _;
        _tax();
    }

    function pay() external payable {
        _paidAmount += msg.value;
    }

    function _tax() internal {
        uint256 taxAmount = _getTaxAmount();
        assembly {
            if xor(tload(TAXED_SLOT.slot), true) {
                tstore(TAXED_SLOT.slot, true)

                // greater than or equal to
                if or(xor(sload(_paidAmount.slot), taxAmount), gt(sload(_paidAmount.slot), taxAmount)) {
                    mstore(0x00, 0xac977714) // 0xac977714 is the 4-byte selector of "NotEnoughPaid()"
                    revert(0x1C, 0x04) // returns the stored 4-byte selector from above
                }
            }
        }
        _afterTax(taxAmount);
    }

    // function to be overridden by tax function implementation
    function _getTaxAmount() internal view virtual returns (uint256) {
        return _getPriorityFee() * 99;
    }

    function _getPriorityFee() internal view returns (uint256) {
        return tx.gasprice - block.basefee;
    }

    /// use this function to implement the tax logic, such as transferring the tax amount to a treasury address
    function _afterTax(uint256 _taxAmount) internal virtual {}
}
