const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying HelivaultToken with the account:", deployer.address);

  // Deploy HelivaultToken
  const HelivaultToken = await ethers.getContractFactory("HelivaultToken");
  const helivaultToken = await HelivaultToken.deploy(deployer.address);
  await helivaultToken.waitForDeployment();

  const tokenAddress = await helivaultToken.getAddress();
  console.log("HelivaultToken deployed to:", tokenAddress);

  // Update deployments.json
  const deploymentsPath = path.join(__dirname, "..", "deployments.json");
  let deployments = {};
  if (fs.existsSync(deploymentsPath)) {
    deployments = JSON.parse(fs.readFileSync(deploymentsPath));
  }

  deployments.HelivaultToken = {
    address: tokenAddress,
    args: [deployer.address],
  };

  fs.writeFileSync(
    deploymentsPath,
    JSON.stringify(
      deployments,
      (key, value) => (typeof value === "bigint" ? value.toString() : value),
      2,
    ),
  );
  console.log(
    "Deployment information for HelivaultToken updated in",
    deploymentsPath,
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
