// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {MEVTax, NotEnoughPaid} from "../src/MEVTax.sol";

/// @title MEVTaxWithTaxApplied
/// @notice This contract exposes a function with the applyTax modifier.
contract MEVTaxWithTaxApplied is MEVTax {
    /// @notice Mock function that applies the tax.
    function mockTaxed() external applyTax {}
}

contract MEVTaxTest is Test {
    MEVTaxWithTaxApplied public mevTax;

    function setUp() public {
        mevTax = new MEVTaxWithTaxApplied();
    }

    /// @dev Tests that payTax succeeds for an arbitrary amount of wei.
    function testFuzz_payTax_succeeds(uint256 _amount) public {
        // make sure the contract has enough balance to pay the tax
        vm.deal(address(this), _amount);

        assertEq(address(mevTax).balance, 0);
        mevTax.payTax{value: _amount}();
        assertEq(address(mevTax).balance, _amount);
    }

    /// @dev Tests that applyTax succeeds when the paid amount is sufficient to cover the tax.
    function testFuzz_applyTax_sufficientPaidAmount_succeeds(uint256 _txGasPrice, uint256 _baseFee, uint256 _paidAmount)
        public
    {
        // assume a priority fee equal or greater than zero
        vm.assume(_txGasPrice >= _baseFee);
        uint256 priorityFeePerGas = _txGasPrice - _baseFee;
        // ensure there's no overflow later
        vm.assume(type(uint256).max / 99 >= priorityFeePerGas);
        // set the tx gas price and base fee
        vm.txGasPrice(_txGasPrice);
        vm.fee(_baseFee);
        // calculate the tax amount
        uint256 taxAmount = priorityFeePerGas * 99;
        // bound the paid amount to be equal or greater than the tax amount
        _paidAmount = bound(_paidAmount, taxAmount, type(uint256).max);

        // make sure the tax is paid for
        testFuzz_payTax_succeeds(_paidAmount);

        mevTax.mockTaxed();
    }

    /// @dev Tests that applyTax reverts when the paid amount is insufficient to cover the tax.
    function testFuzz_applyTax_insufficientPaidAmount_reverts(
        uint256 _txGasPrice,
        uint256 _baseFee,
        uint256 _paidAmount
    ) public {
        // assume a priority fee equal or greater than zero
        vm.assume(_txGasPrice >= _baseFee);
        uint256 priorityFeePerGas = _txGasPrice - _baseFee;
        // ensure there's no overflow later
        vm.assume(type(uint256).max / 99 >= priorityFeePerGas);
        // set the tx gas price and base fee
        vm.txGasPrice(_txGasPrice);
        vm.fee(_baseFee);
        // calculate the tax amount
        uint256 taxAmount = priorityFeePerGas * 99;
        // bound the paid amount to be less than the tax amount
        vm.assume(taxAmount > 0);
        _paidAmount = bound(_paidAmount, 0, taxAmount - 1);

        // make sure the tax is not paid for
        testFuzz_payTax_succeeds(_paidAmount);

        vm.expectRevert(NotEnoughPaid.selector);
        mevTax.mockTaxed();
    }
}
