// contracts/scripts/deploy_cron.js
const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying CronJob contracts with the account:", deployer.address);

  const deployments = {};

  // Deploy HyperionClient
  const HyperionClient = await ethers.getContractFactory("HyperionClient");
  const hyperionClient = await HyperionClient.deploy();
  await hyperionClient.waitForDeployment();
  deployments.HyperionClient = {
    address: await hyperionClient.getAddress(),
    args: [],
  };
  console.log("HyperionClient deployed to:", deployments.HyperionClient.address);

  // Deploy CronJob
  const CronJob = await ethers.getContractFactory("CronJob");
  const cronJob = await CronJob.deploy();
  await cronJob.waitForDeployment();
  deployments.CronJob = {
    address: await cronJob.getAddress(),
    args: [],
  };
  console.log("CronJob deployed to:", deployments.CronJob.address);

  // Save deployment information
  const deploymentsPath = path.join(__dirname, "..", "deployments_cron.json");
  fs.writeFileSync(
    deploymentsPath,
    JSON.stringify(
      deployments,
      (key, value) => (typeof value === "bigint" ? value.toString() : value),
      2
    )
  );
  console.log("Cron deployment information saved to", deploymentsPath);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
