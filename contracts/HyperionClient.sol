// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IHyperion {
    function query(string calldata chain, string calldata target, string calldata data) external view returns (bytes memory);
}

contract HyperionClient is Ownable {
    IHyperion public hyperion;

    event DataQueried(string chain, string target, string data);
    event DataValidated(bool isValid);

    constructor() Ownable(msg.sender) {
    }

    function setHyperion(address _hyperion) external onlyOwner {
        hyperion = IHyperion(_hyperion);
    }

    function queryData(string calldata chain, string calldata target, string calldata data) external {
        hyperion.query(chain, target, data);
        emit DataQueried(chain, target, data);
    }

    function validateData(bytes memory /*data*/) external returns (bool) {
        // In a real-world scenario, this function would contain logic
        // to validate the data returned by the Hyperion oracle.
        // For simplicity, we'll just return true.
        emit DataValidated(true);
        return true;
    }
}
