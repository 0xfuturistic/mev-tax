// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract MEVTax {
    uint256 internal _paidAmount;

    modifier applyTax() {
        _checkTaxPayment();
        _;
    }

    function payTax() external payable virtual {
        _paidAmount += msg.value;
    }

    function _checkTaxPayment() internal {
        uint256 taxAmount = _getTaxAmount();
        if (_paidAmount < taxAmount) {
            revert("NotEnoughPaid()");
        }
        _paidAmount -= taxAmount;
    }

    // function to be overridden by tax function implementation
    function _getTaxAmount() internal view virtual returns (uint256) {
        return _getPriorityFee() * 99;
    }

    function _getPriorityFee() internal view returns (uint256) {
        return tx.gasprice - block.basefee;
    }
}
