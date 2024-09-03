// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Testing utilities
import {Test} from "forge-std/Test.sol";

// Libraries
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

// Target contract dependencies
import {MEVTaxLegacy} from "../src/legacy/MEVTaxLegacy.sol";
import {MEVTaxLegacyBase} from "../src/legacy/MEVTaxLegacyBase.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title MEVTaxWithTaxApplied
/// @notice This contract exposes a function with the applyTax modifier.
contract MEVTaxWithTaxAppliedLegacy is MEVTaxLegacy {
    /// @notice Mock function that applies the tax.
    function mockTax() external payable applyTax {}
}

contract MEVTaxLegacyTest is Test {
    address mockCurrency;
    address mockRecipient;
    MEVTaxWithTaxAppliedLegacy public mevTaxLegacy;

    function setUp() public {
        mockCurrency = address(new ERC20Mock());
        mockRecipient = address(0x2);
        mevTaxLegacy = new MEVTaxWithTaxAppliedLegacy();
        mevTaxLegacy.setCurrency(mockCurrency);
        mevTaxLegacy.setRecipient(mockRecipient);
    }

    /// @dev Tests that the currency can be updated by the owner.
    function testFuzz_setCurrency_owner_succeeds(address _currencyAddress) public {
        mevTaxLegacy.setCurrency(_currencyAddress);
        assertEq(mevTaxLegacy.currency(), _currencyAddress);
    }

    /// @dev Tests that the currency cannot be updated by a non-owner.
    function testFuzz_setCurrency_notOwner_reverts(address _currencyAddress) public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(0)));
        vm.prank(address(0));
        mevTaxLegacy.setCurrency(_currencyAddress);
    }

    /// @dev Tests that the recipient can be successfully updated by the owner
    ///      for arbitrary address _recipient.
    function testFuzz_setRecipient_owner_succeeds(address _recipient) public {
        mevTaxLegacy.setRecipient(_recipient);
        assertEq(mevTaxLegacy.recipient(), _recipient);
    }

    /// @dev Tests that the recipient cannot be updated by a non-owner for
    ///      arbitrary address _recipient.
    function testFuzz_setRecipient_notOwner_reverts(address _recipient) public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(0)));
        vm.prank(address(0));
        mevTaxLegacy.setRecipient(_recipient);
    }

    /// @dev Tests that isCurrencyETH returns correctly for native currency.
    function test_isCurrencyETH_native_succeeds() public {
        assertFalse(mevTaxLegacy.isCurrencyETH());
        testFuzz_setCurrency_owner_succeeds(mevTaxLegacy.ETH_CURRENCY());
        assertTrue(mevTaxLegacy.isCurrencyETH());
    }

    /// @dev Tests that isCurrecyETH returns correctly for non-native currency.
    function testFuzz_isCurrencyETH_nonNative_succeeds(address _currencyAddress) public {
        vm.assume(_currencyAddress != mevTaxLegacy.ETH_CURRENCY());
        testFuzz_setCurrency_owner_succeeds(mevTaxLegacy.ETH_CURRENCY());
        assertTrue(mevTaxLegacy.isCurrencyETH());
        testFuzz_setCurrency_owner_succeeds(_currencyAddress);
        assertFalse(mevTaxLegacy.isCurrencyETH());
    }

    /// @dev Tests that mockTax succeeds when _amount of mockCurrency is
    ///      successfully transferred to mockRecipient for arbitrary _amount,
    ///      _txGasPrice, and _baseFee.
    function testFuzz_mockTax_native_sufficientPaidAmount_succeeds(
        uint256 _amount,
        uint256 _txGasPrice,
        uint256 _baseFee
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
        uint256 taxAmount = mevTaxLegacy.tax(priorityFeePerGas);
        // bound the amount to be equal or greater than the tax amount
        _amount = bound(_amount, taxAmount, type(uint256).max);

        // set currency to native ether
        mevTaxLegacy.setCurrency(mevTaxLegacy.ETH_CURRENCY());

        // mint the amount
        // since _amount is greater than the tax amount, the tax will be paid
        vm.deal(address(this), _amount);
        assertEq(address(this).balance, _amount);

        // apply the tax
        mevTaxLegacy.mockTax{value: _amount}();

        // check that the tax was paid
        assertEq(address(mockRecipient).balance, taxAmount);
    }

    /// @dev Tests that mockTax succeeds when _amount of mockCurrency is
    ///      successfully transferred to mockRecipient for arbitrary _amount,
    ///      _txGasPrice, and _baseFee.
    function testFuzz_mockTax_nonNative_sufficientPaidAmount_succeeds(
        uint256 _amount,
        uint256 _txGasPrice,
        uint256 _baseFee
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
        uint256 taxAmount = mevTaxLegacy.tax(priorityFeePerGas);
        // bound the amount to be equal or greater than the tax amount
        _amount = bound(_amount, taxAmount, type(uint256).max);

        // mint the amount and approve the tax
        // since _amount is greater than the tax amount, the tax will be paid
        _mintAndApprove(_amount);
        assertEq(IERC20(mockCurrency).balanceOf(address(this)), _amount);

        // apply the tax
        mevTaxLegacy.mockTax();

        // check that the tax was paid
        assertEq(IERC20(mockCurrency).balanceOf(address(this)), _amount - taxAmount);
        assertEq(IERC20(mockCurrency).balanceOf(mockRecipient), taxAmount);
    }

    /// @dev Tests that mockTax reverts when _amount of mockCurrency is
    ///      insufficient to cover the tax for arbitrary _amount, _txGasPrice,
    ///      and _baseFee.
    function testFuzz_mockTax_native_insufficientPaidAmount_reverts(
        uint256 _amount,
        uint256 _txGasPrice,
        uint256 _baseFee
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
        uint256 taxAmount = mevTaxLegacy.tax(priorityFeePerGas);
        // bound the paid amount to be less than the tax amount
        vm.assume(taxAmount > 0);
        _amount = bound(_amount, 0, taxAmount - 1);

        // set currency to native ether
        mevTaxLegacy.setCurrency(mevTaxLegacy.ETH_CURRENCY());

        // mint the amount
        // since _amount is greater than the tax amount, the tax will be paid
        vm.deal(address(this), _amount);

        vm.expectRevert(MEVTaxLegacyBase.InsufficientMsgValue.selector);
        mevTaxLegacy.mockTax{value: _amount}();
    }

    /// @dev Tests that mockTax reverts when _amount of mockCurrency is
    ///      insufficient to cover the tax for arbitrary _amount, _txGasPrice,
    ///      and _baseFee.
    function testFuzz_mockTax_nonNative_insufficientPaidAmount_reverts(
        uint256 _amount,
        uint256 _txGasPrice,
        uint256 _baseFee
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
        uint256 taxAmount = mevTaxLegacy.tax(priorityFeePerGas);
        // bound the paid amount to be less than the tax amount
        vm.assume(taxAmount > 0);
        _amount = bound(_amount, 0, taxAmount - 1);

        // mint the amount and approve the tax
        // since _amount is lesser than the tax amount, it shouldn't
        // be possible to cover the tax
        _mintAndApprove(_amount);
        assertEq(IERC20(mockCurrency).balanceOf(address(this)), _amount);

        vm.expectRevert();
        mevTaxLegacy.mockTax();
    }

    /// @dev Internal helper function to mint an arbitrary _amount of
    ///      mockCurrency to this contract and to approve the MEVTax contract
    ///      to spend the minted amount.
    function _mintAndApprove(uint256 _amount) internal {
        ERC20Mock(mockCurrency).mint(address(this), _amount);
        ERC20Mock(mockCurrency).approve(address(mevTaxLegacy), _amount);
    }
}
