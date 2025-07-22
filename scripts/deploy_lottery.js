// contracts/scripts/deploy_lottery.js
const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying Lottery contract with the account:", deployer.address);

  const deploymentsPath = path.join(__dirname, "..", "deployments.json");
  let deployments = {};

  // Read existing deployments if the file exists
  if (fs.existsSync(deploymentsPath)) {
    deployments = JSON.parse(fs.readFileSync(deploymentsPath, "utf8"));
  }

  // Deploy Lottery
  const Lottery = await ethers.getContractFactory("Lottery");
  const lotteryArgs = [ethers.parseEther("0.1")]; // 0.1 HLS entry price
  const lottery = await Lottery.deploy(...lotteryArgs);
  await lottery.waitForDeployment();

  // Update the Lottery deployment info
  deployments.Lottery = {
    address: await lottery.getAddress(),
    args: lotteryArgs,
  };
  console.log("Lottery deployed to:", deployments.Lottery.address);

  // Save the updated deployment information
  fs.writeFileSync(
    deploymentsPath,
    JSON.stringify(
      deployments,
      (key, value) => (typeof value === "bigint" ? value.toString() : value),
      2,
    ),
  );
  console.log("Deployment information updated in", deploymentsPath);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
