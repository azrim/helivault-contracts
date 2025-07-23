const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying HelivaultCollections with the account:", deployer.address);

  const deploymentsPath = path.join(__dirname, "..", "deployments.json");
  let deployments = {};
  if (fs.existsSync(deploymentsPath)) {
    deployments = JSON.parse(fs.readFileSync(deploymentsPath));
  } else {
    console.error("deployments.json not found. Please deploy HelivaultToken first.");
    process.exit(1);
  }

  if (!deployments.HelivaultToken || !deployments.HelivaultToken.address) {
    console.error("HelivaultToken address not found in deployments.json. Please deploy HelivaultToken first.");
    process.exit(1);
  }
  const hvtTokenAddress = deployments.HelivaultToken.address;

  const HelivaultCollections = await ethers.getContractFactory("HelivaultCollections");
  const collectionArgs = [
    hvtTokenAddress,
    "Solar Shards",
    "SSH",
    "https://bafybeih3lbjbvfspg4y4fjjxwizfjcmgav2gnepxu6zs3svfuniefqhruu.ipfs.w3s.link/",
    "https://bafybeih3lbjbvfspg4y4fjjxwizfjcmgav2gnepxu6zs3svfuniefqhruu.ipfs.w3s.link/metadata.json",
    1000, // 10%
    10000,
    ethers.parseEther("0.05"), // 0.05 HVT
  ];
  const helivaultCollections = await HelivaultCollections.deploy(...collectionArgs);
  await helivaultCollections.waitForDeployment();

  deployments.HelivaultCollections = {
    address: await helivaultCollections.getAddress(),
    args: collectionArgs,
  };

  fs.writeFileSync(
    deploymentsPath,
    JSON.stringify(
      deployments,
      (key, value) => (typeof value === "bigint" ? value.toString() : value),
      2
    )
  );

  console.log("HelivaultCollections deployed to:", deployments.HelivaultCollections.address);
  console.log("Deployment information updated in", deploymentsPath);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
