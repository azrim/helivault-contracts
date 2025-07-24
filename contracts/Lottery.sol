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

        // --- New Tiered Payout Logic ---
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender)));
        uint256 payoutAmount;
        uint256 prizePool = address(this).balance;

        // Determine payout based on tiers
        uint256 tier = random % 1000; // Use a scale of 1000 for probability

        if (tier < 10) { // 10 in 1000 chance (1%)
            // Jackpot: 50% of the prize pool
            payoutAmount = prizePool / 2;
        } else if (tier < 60) { // 50 in 1000 chance (5%)
            // Gold: 10% of the prize pool
            payoutAmount = prizePool / 10;
        } else if (tier < 210) { // 150 in 1000 chance (15%)
            // Silver: 2.5% of the prize pool (prizePool / 40)
            payoutAmount = prizePool / 40;
        } else { // 79% chance
            // Consolation: 0.075 HLS fixed
            payoutAmount = 75 * 10**15; // 0.075 ether
        }

        // Ensure the contract has enough funds before paying out
        if (payoutAmount > 0) {
            lastWinner = msg.sender;
            lastWinnerAmount = payoutAmount;
            emit WinnerPaid(msg.sender, payoutAmount);

            if (address(this).balance >= payoutAmount) {
                (bool success, ) = msg.sender.call{value: payoutAmount}("");
                require(success, "Transfer failed.");
            }
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
