const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying CronJob with the account:", deployer.address);

  const CronJob = await ethers.getContractFactory("CronJob");
  const cronJob = await CronJob.deploy();
  await cronJob.waitForDeployment();

  const deploymentsPath = path.join(__dirname, "..", "deployments.json");
  let deployments = {};
  if (fs.existsSync(deploymentsPath)) {
    deployments = JSON.parse(fs.readFileSync(deploymentsPath));
  }

  deployments.CronJob = {
    address: await cronJob.getAddress(),
    args: [],
  };

  fs.writeFileSync(
    deploymentsPath,
    JSON.stringify(
      deployments,
      (key, value) => (typeof value === "bigint" ? value.toString() : value),
      2
    )
  );

  console.log("CronJob deployed to:", deployments.CronJob.address);
  console.log("Deployment information updated in", deploymentsPath);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
