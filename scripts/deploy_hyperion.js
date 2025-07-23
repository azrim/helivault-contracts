const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying HyperionClient with the account:", deployer.address);

  const HyperionClient = await ethers.getContractFactory("HyperionClient");
  const hyperionClient = await HyperionClient.deploy();
  await hyperionClient.waitForDeployment();

  const deploymentsPath = path.join(__dirname, "..", "deployments.json");
  let deployments = {};
  if (fs.existsSync(deploymentsPath)) {
    deployments = JSON.parse(fs.readFileSync(deploymentsPath));
  }

  deployments.HyperionClient = {
    address: await hyperionClient.getAddress(),
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

  console.log("HyperionClient deployed to:", deployments.HyperionClient.address);
  console.log("Deployment information updated in", deploymentsPath);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
