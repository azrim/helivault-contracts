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
    uint256 public rewardRate = 0.0001 * 1e18; // Example: 0.0001 HLV per second

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

    // --- URI Management ---
    function tokenURI(uint256) public view override returns (string memory) {
        return _tokenURI;
    }

    function setTokenURI(string calldata uri) public onlyOwner {
        _tokenURI = uri;
    }

    // --- Sale Management ---
    function setSaleState(SaleState newState) public onlyOwner {
        saleState = newState;
    }

    // --- Whitelist Management ---
    function manageWhitelist(address[] calldata addresses, bool status) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelisted[addresses[i]] = status;
        }
    }

    // --- Minting ---
    function mint(uint256 quantity) public {
        if (saleState == SaleState.Paused) revert SaleNotActive();
        if (currentSupply + quantity > MAX_SUPPLY) revert MaxSupplyReached();
        if (quantity == 0) revert InvalidMintQuantity();
        if (quantity > MAX_PER_MINT) revert MaxPerTxExceeded();
        
        if (saleState == SaleState.Presale) {
            if (!whitelisted[msg.sender]) revert NotWhitelisted();
        }

        uint256 totalCost = MINT_PRICE * quantity;
        if (hlvToken.transferFrom(msg.sender, address(this), totalCost) == false) {
            revert InsufficientPayment();
        }

        for (uint256 i = 0; i < quantity; i++) {
            currentSupply++;
            _safeMint(msg.sender, currentSupply);
        }
    }

    // --- Staking ---
    function stake(uint256[] calldata tokenIds) external nonReentrant {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (ownerOf(tokenIds[i]) != msg.sender) revert NotOwnerOfNFT();
            _safeTransfer(msg.sender, address(this), tokenIds[i], "");
            stakedTokens[tokenIds[i]] = StakedToken({
                owner: msg.sender,
                timestamp: block.timestamp
            });
            userStakedTokenIds[msg.sender].push(tokenIds[i]);
            emit Staked(msg.sender, tokenIds[i]);
        }
    }

    function unstake(uint256[] calldata tokenIds) external nonReentrant {
        claimRewards(); // Claim pending rewards before unstaking
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (stakedTokens[tokenIds[i]].owner != msg.sender) revert NotOwnerOfStakedToken();

            // Remove from user's staked list
            uint256[] storage userTokens = userStakedTokenIds[msg.sender];
            for (uint256 j = 0; j < userTokens.length; j++) {
                if (userTokens[j] == tokenIds[i]) {
                    userTokens[j] = userTokens[userTokens.length - 1];
                    userTokens.pop();
                    break;
                }
            }

            delete stakedTokens[tokenIds[i]];
            _safeTransfer(address(this), msg.sender, tokenIds[i], "");
            emit Unstaked(msg.sender, tokenIds[i]);
        }
    }

    function pendingRewards(address user) public view returns (uint256) {
        uint256 totalRewards = 0;
        uint256[] memory userTokens = userStakedTokenIds[user];
        for (uint256 i = 0; i < userTokens.length; i++) {
            StakedToken memory staked = stakedTokens[userTokens[i]];
            totalRewards += (block.timestamp - staked.timestamp) * rewardRate;
        }
        return totalRewards;
    }

    function claimRewards() public nonReentrant {
        uint256 totalRewards = pendingRewards(msg.sender);
        if (totalRewards == 0) revert NoRewardsToClaim();

        // Reset timestamps for all staked tokens to prevent re-claiming
        uint256[] memory userTokens = userStakedTokenIds[msg.sender];
        for (uint256 i = 0; i < userTokens.length; i++) {
            stakedTokens[userTokens[i]].timestamp = block.timestamp;
        }

        hlvToken.transfer(msg.sender, totalRewards);
        emit RewardsClaimed(msg.sender, totalRewards);
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