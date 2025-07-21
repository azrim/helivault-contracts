// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";

// Interface for the Chronos precompile
interface IChronos {
    function schedule(address to, uint256 value, uint256 gasLimit, uint64 executionTime, bytes calldata data) external returns (bytes32);
    function cancel(bytes32 scheduledId) external;
}

contract CronJob is Ownable {
    // Address of the Chronos precompile on Helios
    IChronos constant chronos = IChronos(0x000000000000000000000000000000000000008A);

    event JobScheduled(bytes32 indexed jobId, address indexed target, uint64 executionTime);
    event JobCancelled(bytes32 indexed jobId);

    constructor() Ownable(msg.sender) {}

    function scheduleJob(
        address _target,
        uint64 _executionTime, // Unix timestamp for when the job should run
        bytes calldata _data
    ) external onlyOwner returns (bytes32) {
        // Ensure the execution time is in the future
        require(_executionTime > block.timestamp, "Execution time must be in the future");

        // Schedule the transaction with Chronos
        // We'll provide a generous gas limit, but this could be estimated more precisely
        bytes32 jobId = chronos.schedule(_target, 0, 200000, _executionTime, _data);

        emit JobScheduled(jobId, _target, _executionTime);
        return jobId;
    }

    function cancelJob(bytes32 _jobId) external onlyOwner {
        chronos.cancel(_jobId);
        emit JobCancelled(_jobId);
    }
}
