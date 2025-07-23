// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract HelivaultCollections is
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable,
    ERC2981,
    Ownable,
    ReentrancyGuard
{
    IERC20 public hvtToken;
    uint256 public maxSupply;
    uint256 public mintPrice;
    string private _customBaseURI;
    string private _hiddenURI;
    bool public revealed;

    constructor(
        address hvtTokenAddress_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory hiddenURI_,
        uint96 royaltyBips,
        uint256 maxSupply_,
        uint256 initialMintPrice_
    ) ERC721(name_, symbol_) Ownable(msg.sender) {
        hvtToken = IERC20(hvtTokenAddress_);
        _customBaseURI = baseURI_;
        _hiddenURI = hiddenURI_;
        maxSupply = maxSupply_;
        _setDefaultRoyalty(msg.sender, royaltyBips);
        mintPrice = initialMintPrice_;
        revealed = false;
    }

    function mint(uint256 quantity) external {
        require(totalSupply() + quantity <= maxSupply, "Max supply reached");
        uint256 totalCost = mintPrice * quantity;
        require(hvtToken.transferFrom(msg.sender, address(this), totalCost), "HVT transfer failed");

        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function airdrop(address[] calldata recipients) external onlyOwner {
        require(totalSupply() + recipients.length <= maxSupply, "Airdrop exceeds max supply");
        for (uint256 i = 0; i < recipients.length; i++) {
            _safeMint(recipients[i], totalSupply() + 1);
        }
    }
    
    function reveal() external onlyOwner {
        revealed = true;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
    
    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _customBaseURI = baseURI_;
    }



    function setRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
    
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawHVT() external onlyOwner nonReentrant {
        uint256 balance = hvtToken.balanceOf(address(this));
        require(hvtToken.transfer(owner(), balance), "HVT transfer failed");
    }

    function _baseURI() internal view override returns (string memory) {
        return revealed ? _customBaseURI : _hiddenURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _update(address to, uint256 id, address auth)
        internal
        override(ERC721, ERC721Enumerable, ERC721Pausable)
        returns (address)
    {
        return super._update(to, id, auth);
    }

    function _increaseBalance(address account, uint128 amount)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, amount);
    }
}
