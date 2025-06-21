// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract HelivaultNFT is
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable,
    ERC2981,
    Ownable
{
    uint256 public tokenId;
    uint256 public maxSupply;
    uint256 public mintPrice = 0.01 ether;
    string private _customBaseURI;
    string private _hiddenURI;
    bool public revealed;

    constructor(
        string memory baseURI_,
        string memory hiddenURI_,
        uint96 royaltyBips,
        uint256 maxSupply_
    ) ERC721("Helivault", "HLV") Ownable(msg.sender) {
        _customBaseURI = baseURI_;
        _hiddenURI = hiddenURI_;
        maxSupply = maxSupply_;
        _setDefaultRoyalty(msg.sender, royaltyBips);
        revealed = false;
    }

    function mint() external payable {
        require(tokenId < maxSupply, "Max supply reached");
        require(msg.value >= mintPrice, "Insufficient payment");

        tokenId++;
        _safeMint(msg.sender, tokenId);
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

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
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
