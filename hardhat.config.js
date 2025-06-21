require("dotenv").config();
require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: "0.8.20",
  networks: {
    helios: {
      url: "https://testnet1.helioschainlabs.org",
      chainId: 42000,
      accounts: [process.env.PRIVATE_KEY]
    }
  }
};
