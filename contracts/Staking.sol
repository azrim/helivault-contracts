// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IHyperion {
    function query(string calldata chain, string calldata target, string calldata data) external view returns (bytes memory);
}

interface IAIAgent {
    function getRewardRate(uint256 totalStaked) external view returns (uint256);
}

contract Staking is Ownable {
    ERC20 public stakingToken;
    ERC20 public rewardsToken;

    IHyperion public hyperion;
    IAIAgent public aiAgent;

    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public rewards;

    uint256 public totalStaked;
    uint256 public rewardRate; 

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardRateUpdated(uint256 newRate);

    constructor() Ownable(msg.sender) {
        rewardRate = 1; // Default reward rate
    }

    function setStakingToken(address _stakingToken) external onlyOwner {
        stakingToken = ERC20(_stakingToken);
    }

    function setRewardsToken(address _rewardsToken) external onlyOwner {
        rewardsToken = ERC20(_rewardsToken);
    }

    function setHyperion(address _hyperion) external onlyOwner {
        hyperion = IHyperion(_hyperion);
    }

    function setAIAgent(address _aiAgent) external onlyOwner {
        aiAgent = IAIAgent(_aiAgent);
    }

    function setRewardRate(uint256 newRate) public onlyOwner {
        rewardRate = newRate;
        emit RewardRateUpdated(newRate);
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake 0");
        _updateRewards(msg.sender);
        stakingToken.transferFrom(msg.sender, address(this), amount);
        stakedBalance[msg.sender] += amount;
        totalStaked += amount;
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external {
        require(stakedBalance[msg.sender] >= amount, "Insufficient staked balance");
        _updateRewards(msg.sender);
        stakedBalance[msg.sender] -= amount;
        totalStaked -= amount;
        stakingToken.transfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    function claimReward() external {
        _updateRewards(msg.sender);
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function updateRewardRateFromAI() external onlyOwner {
        uint256 newRate = aiAgent.getRewardRate(totalStaked);
        setRewardRate(newRate);
    }

    function getExternalData(string calldata chain, string calldata target, string calldata data) external view returns (bytes memory) {
        return hyperion.query(chain, target, data);
    }

    function distributeRewardsDaily() external onlyOwner {
        address[] memory stakers = _getStakers();
        for (uint i = 0; i < stakers.length; i++) {
            _updateRewards(stakers[i]);
        }
    }

    function _updateRewards(address user) internal {
        uint256 staked = stakedBalance[user];
        if (staked > 0) {
            uint256 reward = (staked * rewardRate) / 1e18;
            rewards[user] += reward;
        }
    }

    function _getStakers() internal view returns (address[] memory) {
        return new address[](0);
    }
}
