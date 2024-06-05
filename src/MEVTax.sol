// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MEVTax {
    address public owner;
    uint256 public taxRate; // Multiplier for the MEV tax (e.g., 99 for 99%)

    event TaxCollected(address indexed from, uint256 amount, uint256 priorityFee);
    event TaxDistributed(address indexed to, uint256 amount);
    event TaxRateChanged(uint256 newRate);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    constructor(uint256 initialTaxRate) {
        require(initialTaxRate > 0, "Tax rate must be greater than zero");
        owner = msg.sender;
        taxRate = initialTaxRate;
    }

    function setTaxRate(uint256 newRate) external onlyOwner {
        require(newRate > 0, "Tax rate must be greater than zero");
        taxRate = newRate;
        emit TaxRateChanged(newRate);
    }

    function getPriorityFeePerGas() public view returns (uint256) {
        // Calculate the priority fee per gas
        return tx.gasprice - block.basefee;
    }

    function imposeMEVTax() external payable {
        uint256 priorityFeePerGas = getPriorityFeePerGas();
        uint256 totalGasUsed = gasleft();
        uint256 priorityFee = priorityFeePerGas * totalGasUsed;

        uint256 taxAmount = taxRate * priorityFee;
        require(msg.value >= taxAmount, "Insufficient tax payment");

        emit TaxCollected(msg.sender, taxAmount, priorityFee);
    }

    function distributeTaxRevenue(address payable[] memory recipients, uint256[] memory amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Recipients and amounts length mismatch");

        for (uint256 i = 0; i < recipients.length; i++) {
            recipients[i].transfer(amounts[i]);
            emit TaxDistributed(recipients[i], amounts[i]);
        }
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {}

    fallback() external payable {}
}
