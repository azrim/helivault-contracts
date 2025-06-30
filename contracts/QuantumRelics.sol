// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // <-- IMPORT ADDED
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/**
 * @title QuantumRelics
 * @dev An ERC721 contract with enumerable functions for history tracking.
 */
// Inherit from ERC721Enumerable
contract QuantumRelics is ERC721, ERC721Enumerable, Ownable, ERC2981 {
    // --- Custom Errors ---
    error SaleNotActive();
    error NotWhitelisted();
    error MaxSupplyReached();
    error InvalidMintQuantity();
    error MaxPerTxExceeded();
    error InsufficientPayment();

    // --- State Variables ---
    enum SaleState { Paused, Presale, Public }
    SaleState public saleState;

    uint256 public constant MAX_SUPPLY = 3999;
    uint256 public constant MINT_PRICE = 0.39 * 10**18; // 0.39 HLV
    uint256 public constant MAX_PER_MINT = 10;
    
    string private _tokenURI;
    uint256 public currentSupply;
    
    IERC20 public hlvToken;
    mapping(address => bool) public whitelisted;

    // --- Constructor ---
    constructor(
        address _hlvTokenAddress,
        address _royaltyReceiver,
        uint96 _royaltyFeeNumerator
    ) ERC721("Helivault NFT", "QR") Ownable(msg.sender) {
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

    // --- Royalties ---
    function setRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
    
    // --- Overrides for Enumerable ---
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