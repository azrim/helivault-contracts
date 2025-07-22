// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Lottery is Ownable, ReentrancyGuard {
    uint256 public entryPrice;
    uint256 public lastWinnerAmount;
    address public lastWinner;

    event WinnerPaid(address indexed winner, uint256 amount);

    constructor(uint256 _entryPrice) Ownable(msg.sender) {
        entryPrice = _entryPrice;
    }

    function enter() external payable nonReentrant {
        require(msg.value == entryPrice, "Incorrect entry price");

        // --- Tiered Payout Logic ---
        // This is pseudo-random and not suitable for a production mainnet.
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender)));
        uint256 payoutAmount;

        // Determine payout based on tiers
        uint256 tier = random % 1000; // Use a scale of 1000 for probability

        if (tier == 0) { // 1 in 1000 chance (0.1%)
            payoutAmount = entryPrice * 25; // Jackpot: 25x
        } else if (tier < 21) { // 20 in 1000 chance (2%)
            payoutAmount = entryPrice * 3; // Big Win: 3x
        } else if (tier < 121) { // 100 in 1000 chance (10%)
            payoutAmount = (entryPrice * 3) / 2; // Nice Profit: 1.5x
        } else { // ~88% chance
            payoutAmount = entryPrice / 2; // Consolation: 0.5x
        }

        // Ensure the contract has enough funds before paying out
        if (address(this).balance >= payoutAmount && payoutAmount > 0) {
            (bool success, ) = msg.sender.call{value: payoutAmount}("");
            require(success, "Transfer failed.");
            
            lastWinner = msg.sender;
            lastWinnerAmount = payoutAmount;
            emit WinnerPaid(msg.sender, payoutAmount);
        }
        // If the contract is out of funds, the player's entry fee is kept,
        // but no prize is paid out. The owner should fund the contract.
    }

    function setEntryPrice(uint256 _newPrice) external onlyOwner {
        entryPrice = _newPrice;
    }

    function fund() external payable onlyOwner {
        // Allows the owner to add HLS to the contract for payouts
    }

    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Withdrawal failed.");
    }

    // Allow contract to receive HLS
    receive() external payable {}
}
