// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract DailyCheckIn {
    // Mapping from user address to their last check-in timestamp
    mapping(address => uint256) public lastCheckIn;
    // Mapping from user address to their current streak
    mapping(address => uint256) public streaks;

    // Event to be emitted on a successful check-in
    event CheckedIn(address indexed user, uint256 newStreak);

    // Function for users to check-in
    function checkIn() public {
        address user = msg.sender;
        uint256 last = lastCheckIn[user];
        uint256 now_ = block.timestamp;

        // Check if the user has already checked in today
        require(now_ / 1 days > last / 1 days, "Already checked in today");

        // Check if the streak is continued
        if (now_ / 1 days == last / 1 days + 1) {
            streaks[user]++;
        } else {
            // If the streak is broken, reset to 1
            streaks[user] = 1;
        }

        // Update the last check-in time
        lastCheckIn[user] = now_;

        emit CheckedIn(user, streaks[user]);
    }

    // Function to get the current streak of a user
    function getStreak(address user) public view returns (uint256) {
        return streaks[user];
    }
}