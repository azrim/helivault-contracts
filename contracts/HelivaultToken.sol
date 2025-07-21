// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HelivaultToken is ERC20, ERC20Burnable, ERC20Pausable, Ownable {
    mapping(address => uint256) public lastFaucetUse;
    uint256 public faucetAmount = 1 * 10**17; // 0.1 HVT
    uint256 public faucetCooldown = 24 hours;

    constructor(address initialOwner) ERC20("Helivault Token", "HVT") Ownable(initialOwner) {
        _mint(msg.sender, 21000000 * 10 ** decimals());
    }

    function faucet() public {
        require(block.timestamp >= lastFaucetUse[msg.sender] + faucetCooldown, "Faucet is on cooldown");
        lastFaucetUse[msg.sender] = block.timestamp;
        _mint(msg.sender, faucetAmount);
    }

    function setFaucetAmount(uint256 _amount) public onlyOwner {
        faucetAmount = _amount * 10**decimals();
    }

    function setFaucetCooldown(uint256 _cooldown) public onlyOwner {
        faucetCooldown = _cooldown;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Pausable)
    {
        super._update(from, to, value);
    }
}
