// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";

contract HyperionClient is Ownable {
    uint256 public lastExecutionTimestamp;
    address public lastCaller;

    event JobExecuted(address indexed caller, uint256 timestamp);

    constructor() Ownable(msg.sender) {}

    // This is the function that the CronJob will call
    function execute() external {
        lastExecutionTimestamp = block.timestamp;
        lastCaller = msg.sender;
        emit JobExecuted(msg.sender, block.timestamp);
    }

    // Allow the owner to withdraw any funds sent to this contract
    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}
