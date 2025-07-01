// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title QuantumRelics
 * @dev An all-in-one ERC721 contract with minting, sale management, royalties, and staking.
 */
contract QuantumRelics is ERC721, ERC721Enumerable, Ownable, ERC2981, ReentrancyGuard {
    // --- Custom Errors ---
    error SaleNotActive();
    error NotWhitelisted();
    error MaxSupplyReached();
    error InvalidMintQuantity();
    error MaxPerTxExceeded();
    error InsufficientPayment();
    error NotOwnerOfStakedToken();
    error NoRewardsToClaim();
    error NotOwnerOfNFT();
    error TokenAlreadyStaked();
    error TokenNotStaked();

    // --- State Variables ---
    enum SaleState { Paused, Presale, Public }
    SaleState public saleState;

    uint256 public constant MAX_SUPPLY = 3999;
    uint256 public constant MINT_PRICE = 0.39 * 10**18;
    uint256 public constant MAX_PER_MINT = 10;
    
    string private _tokenURI;
    uint256 public currentSupply;
    
    IERC20 public hlvToken;
    mapping(address => bool) public whitelisted;

    // --- Staking State Variables ---
    struct StakedToken {
        address owner;
        uint256 timestamp;
    }
    mapping(uint256 => StakedToken) public stakedTokens;
    mapping(address => uint256[]) public userStakedTokenIds;
    uint256 public rewardRate = 0.0001 * 1e18;

    // --- Events ---
    event Staked(address indexed owner, uint256 tokenId);
    event Unstaked(address indexed owner, uint256 tokenId);
    event RewardsClaimed(address indexed owner, uint256 amount);

    // --- Constructor ---
    constructor(
        address _hlvTokenAddress,
        address _royaltyReceiver,
        uint96 _royaltyFeeNumerator
    ) ERC721("Quantum Relic", "QR") Ownable(msg.sender) {
        hlvToken = IERC20(_hlvTokenAddress);
        _setDefaultRoyalty(_royaltyReceiver, _royaltyFeeNumerator);
        saleState = SaleState.Paused;
    }

    // --- URI, Sale, Whitelist, and Minting functions remain the same ---
    // ... (paste your existing functions here)

    // --- Staking ---
    function stake(uint256[] calldata tokenIds) external nonReentrant {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (ownerOf(tokenId) != msg.sender) revert NotOwnerOfNFT();
            if (stakedTokens[tokenId].owner != address(0)) revert TokenAlreadyStaked();

            _safeTransfer(msg.sender, address(this), tokenId, "");
            stakedTokens[tokenId] = StakedToken({
                owner: msg.sender,
                timestamp: block.timestamp
            });
            userStakedTokenIds[msg.sender].push(tokenId);
            emit Staked(msg.sender, tokenId);
        }
    }

    function unstake(uint256[] calldata tokenIds) external nonReentrant {
        claimRewards();
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (stakedTokens[tokenId].owner != msg.sender) revert NotOwnerOfStakedToken();
<<<<<<< HEAD
            if (stakedTokens[tokenId].owner == address(0)) revert TokenNotStaked();

            uint256[] storage userTokens = userStakedTokenIds[msg.sender];
            for (uint256 j = 0; j < userTokens.length; j++) {
                if (userTokens[j] == tokenId) {
                    userTokens[j] = userTokens[userTokens.length - 1];
                    userTokens.pop();
                    break;
                }
            }

            delete stakedTokens[tokenId];
            _safeTransfer(address(this), msg.sender, tokenId, "");
            emit Unstaked(msg.sender, tokenId);
        }
    }

    // ... (pendingRewards, claimRewards, getStakedTokenIds, and other functions remain the same) ...

    function claimRewards() public nonReentrant {
        uint256 totalRewards = pendingRewards(msg.sender);
        if (totalRewards == 0) revert NoRewardsToClaim();

        uint256[] memory userTokens = userStakedTokenIds[msg.sender];
        for (uint256 i = 0; i < userTokens.length; i++) {
            stakedTokens[userTokens[i]].timestamp = block.timestamp;
        }

        hlvToken.transfer(msg.sender, totalRewards);
        emit RewardsClaimed(msg.sender, totalRewards);
    }

    function getStakedTokenIds(address user) public view returns (uint256[] memory) {
        return userStakedTokenIds[user];
    }
    
    // --- Royalties ---
    function setRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
    
    // --- Overrides ---
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    // --- Withdraw ---
    function withdrawHlv() public onlyOwner {
        uint256 balance = hlvToken.balanceOf(address(this));
        require(balance > 0, "No HLV tokens to withdraw");
        hlvToken.transfer(owner(), balance);
    }
}