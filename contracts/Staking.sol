// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Staking is Ownable, ReentrancyGuard {

    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardsToken;

    mapping(address => uint256) public stakedBalances;
    mapping(address => uint256) public rewards;

    uint256 public totalStaked;
    uint256 public rewardRate; // Wei per second
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event Funded(address indexed funder, uint256 amount);

    constructor(
        address _stakingToken,
        address _rewardsToken
    ) Ownable(msg.sender) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
    }

    function setRewardRate(uint256 _newRate) external onlyOwner {
        updateRewardPerToken();
        rewardRate = _newRate;
    }

    function fund(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Cannot fund with 0");
        rewardsToken.transferFrom(msg.sender, address(this), _amount);
        emit Funded(msg.sender, _amount);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored +
            (((block.timestamp - lastUpdateTime) * rewardRate) * 1e18) / totalStaked;
    }

    function userRewards(address _user) public view returns (uint256) {
        return (stakedBalances[_user] * (rewardPerToken() - rewards[_user])) / 1e18;
    }

    function updateRewardPerToken() internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
    }

    function stake(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Cannot stake 0");
        updateRewardPerToken();
        rewards[msg.sender] = userRewards(msg.sender);
        stakedBalances[msg.sender] = stakedBalances[msg.sender] + _amount;
        totalStaked = totalStaked + _amount;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }

    function unstake(uint256 _amount) external nonReentrant {
        require(stakedBalances[msg.sender] >= _amount, "Insufficient staked balance");
        updateRewardPerToken();
        rewards[msg.sender] = userRewards(msg.sender);
        stakedBalances[msg.sender] = stakedBalances[msg.sender] - _amount;
        totalStaked = totalStaked - _amount;
        stakingToken.transfer(msg.sender, _amount);
        emit Unstaked(msg.sender, _amount);
    }

    function claimRewards() external nonReentrant {
        updateRewardPerToken();
        uint256 reward = userRewards(msg.sender);
        require(reward > 0, "No rewards to claim");
        require(rewardsToken.balanceOf(address(this)) >= reward, "Insufficient reward balance in contract");
        rewards[msg.sender] = rewardPerTokenStored;
        rewardsToken.transfer(msg.sender, reward);
        emit RewardPaid(msg.sender, reward);
    }
}
