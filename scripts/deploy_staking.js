// scripts/deploy_staking.js

const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying Staking contract with the account:", deployer.address);

  // --- Deployment Configuration ---
  const nftAddress = "0x7Ff13298e0c5Dd7CDaBa7606166Ffd9aaD9c0b18"; // QuantumRelics contract address
  const rewardsTokenAddress = "0x63fA6040C99bFd93cAA54B1633aC8f7b348D588a"; // HelivaultToken contract address
  // --- End of Configuration ---

  // Deploy Staking
  console.log("\nDeploying Staking contract...");
  const Staking = await ethers.getContractFactory("Staking");
  const staking = await Staking.deploy(nftAddress, rewardsTokenAddress);
  await staking.waitForDeployment();
  const stakingAddress = await staking.getAddress();
  console.log(`✅ Staking contract deployed to: ${stakingAddress}`);
}

main().catch((error) => {
  console.error("❌ Deployment failed:", error);
  process.exit(1);
});