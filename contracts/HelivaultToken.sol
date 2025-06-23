// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title HelivaultToken
 * @dev An ERC20 token with a faucet for users to claim tokens.
 */
contract HelivaultToken is ERC20, Ownable {
    // Amount of tokens a user can claim from the faucet. (3.9 HLV)
    uint256 public constant FAUCET_AMOUNT = 3.9 * 10**18;

    // Cooldown period for the faucet in seconds (12 hours).
    uint256 public constant FAUCET_COOLDOWN = 12 hours;

    // Mapping to store the last time an address claimed from the faucet.
    mapping(address => uint256) public lastClaimed;

    /**
     * @dev Sets the values for {name} and {symbol}.
     * The total supply of 1,000,000 tokens is minted to the contract deployer.
     */
    constructor() ERC20("Helivault Token", "HLV") Ownable(msg.sender) {
        _mint(msg.sender, 1000000 * 10**18);
    }

    /**
     * @dev Allows a user to claim tokens from the faucet.
     * The user must wait for the cooldown period to pass before claiming again.
     */
    function claim() public {
        require(block.timestamp >= lastClaimed[msg.sender] + FAUCET_COOLDOWN, "Faucet cooldown not over yet");
        lastClaimed[msg.sender] = block.timestamp;
        _mint(msg.sender, FAUCET_AMOUNT);
    }
}