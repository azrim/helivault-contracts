// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Staking is ReentrancyGuard {
    IERC721 public nft;
    IERC20 public rewardsToken;

    // A struct to store information about a staked token
    struct StakedToken {
        address owner;
        uint256 tokenId;
        uint256 timestamp;
    }

    // Mapping from a user's address to their staked tokens
    mapping(address => StakedToken[]) public stakedTokens;

    // Mapping to track who owns which staked token for quick lookups
    mapping(uint256 => address) public tokenOwner;

    // Rewards per second per NFT staked
    uint256 public rewardRate = 0.0001 * 1e18; // Example: 0.0001 HLV per second

    // Event to be emitted on a successful stake
    event Staked(address indexed owner, uint256 tokenId);
    // Event to be emitted on a successful unstake
    event Unstaked(address indexed owner, uint256 tokenId);
    // Event to be emitted when rewards are claimed
    event RewardsClaimed(address indexed owner, uint256 amount);

    constructor(address _nftAddress, address _rewardsTokenAddress) {
        nft = IERC721(_nftAddress);
        rewardsToken = IERC20(_rewardsTokenAddress);
    }

    // Function for users to stake one or more NFTs
    function stake(uint256[] calldata tokenIds) external nonReentrant {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(nft.ownerOf(tokenIds[i]) == msg.sender, "You don't own this NFT");
            nft.transferFrom(msg.sender, address(this), tokenIds[i]);
            stakedTokens[msg.sender].push(StakedToken({
                owner: msg.sender,
                tokenId: tokenIds[i],
                timestamp: block.timestamp
            }));
            tokenOwner[tokenIds[i]] = msg.sender;
            emit Staked(msg.sender, tokenIds[i]);
        }
    }

    // Function for users to unstake one or more NFTs
    function unstake(uint256[] calldata tokenIds) external nonReentrant {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenOwner[tokenIds[i]] == msg.sender, "You are not the owner of this staked token");

            // First, claim any pending rewards
            claimRewards();

            // Find and remove the token from the user's staked tokens array
            StakedToken[] storage userTokens = stakedTokens[msg.sender];
            for (uint256 j = 0; j < userTokens.length; j++) {
                if (userTokens[j].tokenId == tokenIds[i]) {
                    userTokens[j] = userTokens[userTokens.length - 1];
                    userTokens.pop();
                    break;
                }
            }

            delete tokenOwner[tokenIds[i]];
            nft.transferFrom(address(this), msg.sender, tokenIds[i]);
            emit Unstaked(msg.sender, tokenIds[i]);
        }
    }

    // Function to calculate the total pending rewards for a user
    function pendingRewards(address user) external view returns (uint256) {
        uint256 totalRewards = 0;
        StakedToken[] memory userTokens = stakedTokens[user];
        for (uint256 i = 0; i < userTokens.length; i++) {
            totalRewards += (block.timestamp - userTokens[i].timestamp) * rewardRate;
        }
        return totalRewards;
    }

    // Function for users to claim their earned rewards
    function claimRewards() public nonReentrant {
        uint256 totalRewards = 0;
        StakedToken[] storage userTokens = stakedTokens[msg.sender];
        
        for (uint256 i = 0; i < userTokens.length; i++) {
            totalRewards += (block.timestamp - userTokens[i].timestamp) * rewardRate;
            userTokens[i].timestamp = block.timestamp; // Reset the timestamp after calculating rewards
        }

        if (totalRewards > 0) {
            rewardsToken.transfer(msg.sender, totalRewards);
            emit RewardsClaimed(msg.sender, totalRewards);
        }
    }
}