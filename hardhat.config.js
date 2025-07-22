require("dotenv").config();
require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: "0.8.26", // Upgraded to a newer version
  networks: {
    helios: {
      url: "https://testnet1.helioschainlabs.org",
      chainId: 42000,
      accounts: [process.env.PRIVATE_KEY],
    },
  },
};
