// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {MEVTax} from "../src/MEVTax.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title MEVTaxWithTaxApplied
/// @notice This contract exposes a function with the applyTax modifier.
contract MEVTaxWithTaxApplied is MEVTax {
    /// @notice Mock function that applies the tax.
    function mockTaxed() external payable applyTax {}
}

contract MEVTaxTest is Test {
    MEVTaxWithTaxApplied public mevTax;

    function setUp() public {
        mevTax = new MEVTaxWithTaxApplied();
    }

    /// @dev Tests that the recipient is updated successfully by the owner.
    function test_updateRecipient_owner_succeeds(address payable _recipient) public {
        mevTax.setRecipient(_recipient);
        assertEq(mevTax.recipient(), _recipient);
    }

    /// @dev Tests that the recipient is not updated by a non-owner.
    function test_updateRecipient_notOwner_reverts(address payable _recipient) public {
        vm.expectRevert();
        vm.prank(address(0));
        mevTax.setRecipient(_recipient);
    }

    /// @dev Tests that applyTax succeeds when the paid amount is sufficient to cover the tax.
    function testFuzz_applyTax_sufficientPaidAmount_succeeds(
        address payable _recipient,
        uint256 _txGasPrice,
        uint256 _baseFee,
        uint256 _paidAmount
    ) public {
        assumeNotPrecompile(_recipient);
        assumePayable(_recipient);
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

        // set the recipient
        mevTax.setRecipient(_recipient);
        assertEq(mevTax.recipient(), _recipient);

        // ensure the contract has enough balance to transfer paid amount
        vm.deal(address(this), _paidAmount);

        vm.expectCall(_recipient, taxAmount, "");

        mevTax.mockTaxed{value: _paidAmount}();
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

        // ensure the contract has enough balance to transfer paid amount
        vm.deal(address(this), _paidAmount);

        vm.expectRevert(MEVTax.NotEnoughPaid.selector);
        mevTax.mockTaxed{value: _paidAmount}();
    }
}
