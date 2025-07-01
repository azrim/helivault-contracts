// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CronJob is Ownable {
    address public stakingContract;
    uint256 public lastExecution;
    uint24 public constant EXECUTION_INTERVAL = 24 hours;

    constructor() Ownable(msg.sender) {
        lastExecution = block.timestamp;
    }

    function setStakingContract(address stakingContractAddress) external onlyOwner {
        stakingContract = stakingContractAddress;
    }

    function execute() external {
        require(
            block.timestamp >= lastExecution + EXECUTION_INTERVAL,
            "CronJob: Not time to execute yet"
        );
        (bool success, ) = stakingContract.call(abi.encodeWithSignature("distributeRewardsDaily()"));
        require(success, "CronJob: Failed to call distributeRewardsDaily");
        lastExecution = block.timestamp;
    }
}