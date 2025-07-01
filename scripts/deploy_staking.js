// scripts/deploy_staking.js

const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy HelivaultToken
  console.log("\nDeploying HelivaultToken contract...");
  const HelivaultToken = await ethers.getContractFactory("HelivaultToken");
  const hlvToken = await HelivaultToken.deploy();
  await hlvToken.waitForDeployment();
  const hlvTokenAddress = await hlvToken.getAddress();
  console.log(`✅ HelivaultToken deployed to: ${hlvTokenAddress}`);

  // Deploy AIAgent
  console.log("\nDeploying AIAgent contract...");
  const AIAgent = await ethers.getContractFactory("AIAgent");
  const aiAgent = await AIAgent.deploy();
  await aiAgent.waitForDeployment();
  const aiAgentAddress = await aiAgent.getAddress();
  console.log(`✅ AIAgent deployed to: ${aiAgentAddress}`);

  // Deploy HyperionClient
  console.log("\nDeploying HyperionClient contract...");
  const HyperionClient = await ethers.getContractFactory("HyperionClient");
  const hyperionClient = await HyperionClient.deploy();
  await hyperionClient.waitForDeployment();
  const hyperionClientAddress = await hyperionClient.getAddress();
  console.log(`✅ HyperionClient deployed to: ${hyperionClientAddress}`);

  // Deploy Staking
  console.log("\nDeploying Staking contract...");
  const Staking = await ethers.getContractFactory("Staking");
  const staking = await Staking.deploy();
  await staking.waitForDeployment();
  const stakingAddress = await staking.getAddress();
  console.log(`✅ Staking deployed to: ${stakingAddress}`);

  // Deploy CronJob
  console.log("\nDeploying CronJob contract...");
  const CronJob = await ethers.getContractFactory("CronJob");
  const cronJob = await CronJob.deploy();
  await cronJob.waitForDeployment();
  const cronJobAddress = await cronJob.getAddress();
  console.log(`✅ CronJob deployed to: ${cronJobAddress}`);

  // Configure HyperionClient
  console.log("\nConfiguring HyperionClient contract...");
  await hyperionClient.setHyperion(deployer.address); // Using deployer as a placeholder for the Hyperion oracle
  console.log("-> Hyperion oracle set");

  // Configure Staking contract
  console.log("\nConfiguring Staking contract...");
  await staking.setStakingToken(hlvTokenAddress);
  console.log("-> Staking token set");
  await staking.setRewardsToken(hlvTokenAddress);
  console.log("-> Rewards token set");
  await staking.setHyperion(hyperionClientAddress);
  console.log("-> Hyperion client set");
  await staking.setAIAgent(aiAgentAddress);
  console.log("-> AI agent set");

  // Configure CronJob contract
  console.log("\nConfiguring CronJob contract...");
  await cronJob.setStakingContract(stakingAddress);
  console.log("-> Staking contract set");

  console.log("\n🚀 Deployment and configuration complete! 🚀");
}

main().catch((error) => {
  console.error("❌ Deployment failed:", error);
  process.exit(1);
});
