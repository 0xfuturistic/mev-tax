// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {MEVTax} from "../src/MEVTax.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title MEVTaxWithTaxApplied
/// @notice This contract exposes a function with the applyTax modifier.
contract MEVTaxWithTaxApplied is MEVTax {
    /// @notice Mock function that applies the tax.
    function mockTax() external payable applyTax {}
}

contract MEVTaxTest is Test {
    ERC20Mock mockCurrency;
    address mockRecipient;
    MEVTaxWithTaxApplied public mevTax;

    function setUp() public {
        mockCurrency = new ERC20Mock();
        mockRecipient = address(0x2);
        mevTax = new MEVTaxWithTaxApplied();
        mevTax.setCurrency(mockCurrency);
        mevTax.setRecipient(mockRecipient);
    }

    /// @dev Tests that the currency is updated successfully by the owner.
    function test_setCurrency_owner_succeeds(IERC20 _currency) public {
        mevTax.setCurrency(_currency);
        assertEq(address(mevTax.currency()), address(_currency));
    }

    /// @dev Tests that the currency is not updated by a non-owner.
    function test_setCurrency_notOwner_reverts(IERC20 _currency) public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(0)));
        vm.prank(address(0));
        mevTax.setCurrency(_currency);
    }

    /// @dev Tests that the recipient is updated successfully by the owner.
    function test_setRecipient_owner_succeeds(address _recipient) public {
        mevTax.setRecipient(_recipient);
        assertEq(mevTax.recipient(), _recipient);
    }

    /// @dev Tests that the recipient is not updated by a non-owner.
    function test_setRecipient_notOwner_reverts(address _recipient) public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(0)));
        vm.prank(address(0));
        mevTax.setRecipient(_recipient);
    }

    /// @dev Tests that applyTax succeeds when the paid amount is sufficient to
    ///      cover the tax.
    function testFuzz_applyTax_sufficientPaidAmount_succeeds(
        address _recipient,
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

        // mint the paid amount and approve the tax
        // since _paidAmount is greater than the tax amount, the tax will be paid
        _mintAndApprove(_paidAmount);
        assertEq(mockCurrency.balanceOf(address(this)), _paidAmount);

        // apply the tax
        mevTax.mockTax();

        // check that the tax was paid
        assertEq(mockCurrency.balanceOf(address(this)), _paidAmount - taxAmount);
        assertEq(mockCurrency.balanceOf(_recipient), taxAmount);
    }

    /// @dev Tests that applyTax reverts when the paid amount is insufficient to
    ///      cover the tax.
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

        // mint the paid amount and approve the tax
        // since _paidAmount is lesser than the tax amount, it shouldn't be possible
        // to cover the tax
        _mintAndApprove(_paidAmount);
        assertEq(mockCurrency.balanceOf(address(this)), _paidAmount);

        vm.expectRevert();
        mevTax.mockTax();
    }

    function _mintAndApprove(uint256 _amount) internal {
        mockCurrency.mint(address(this), _amount);
        mockCurrency.approve(address(mevTax), _amount);
    }
}
