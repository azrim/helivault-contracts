// scripts/deploy_daily_check_in.js

const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying DailyCheckIn contract with the account:", deployer.address);

  // Deploy DailyCheckIn
  console.log("\nDeploying DailyCheckIn contract...");
  const DailyCheckIn = await ethers.getContractFactory("DailyCheckIn");
  const dailyCheckIn = await DailyCheckIn.deploy();
  await dailyCheckIn.waitForDeployment();
  const dailyCheckInAddress = await dailyCheckIn.getAddress();
  console.log(`✅ DailyCheckIn deployed to: ${dailyCheckInAddress}`);
}

main().catch((error) => {
  console.error("❌ Deployment failed:", error);
  process.exit(1);
});