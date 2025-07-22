const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const deployments = {};

  // Deploy DailyCheckIn
  const DailyCheckIn = await ethers.getContractFactory("DailyCheckIn");
  const dailyCheckIn = await DailyCheckIn.deploy();
  await dailyCheckIn.waitForDeployment();
  deployments.DailyCheckIn = {
    address: await dailyCheckIn.getAddress(),
    args: [],
  };
  console.log("DailyCheckIn deployed to:", deployments.DailyCheckIn.address);

  // Deploy HelivaultCollections
  const HelivaultCollections = await ethers.getContractFactory("HelivaultCollections");
  const collectionArgs = [
    "Solar Shards",
    "SSH",
    "https://bafybeih3lbjbvfspg4y4fjjxwizfjcmgav2gnepxu6zs3svfuniefqhruu.ipfs.w3s.link/",
    "https://bafybeih3lbjbvfspg4y4fjjxwizfjcmgav2gnepxu6zs3svfuniefqhruu.ipfs.w3s.link/metadata.json",
    1000, // 10%
    10000,
    ethers.parseEther("0.1"),
  ];
  const helivaultCollections = await HelivaultCollections.deploy(...collectionArgs);
  await helivaultCollections.waitForDeployment();
  deployments.HelivaultCollections = {
    address: await helivaultCollections.getAddress(),
    args: collectionArgs,
  };
  console.log("HelivaultCollections deployed to:", deployments.HelivaultCollections.address);

  // Deploy HelivaultToken
  const HelivaultToken = await ethers.getContractFactory("HelivaultToken");
  const helivaultToken = await HelivaultToken.deploy(deployer.address);
  await helivaultToken.waitForDeployment();
  deployments.HelivaultToken = {
    address: await helivaultToken.getAddress(),
    args: [deployer.address],
  };
  console.log("HelivaultToken deployed to:", deployments.HelivaultToken.address);

  // Deploy Lottery
  const Lottery = await ethers.getContractFactory("Lottery");
  const lotteryArgs = [ethers.parseEther("0.1")]; // 0.1 HLS entry price
  const lottery = await Lottery.deploy(...lotteryArgs);
  await lottery.waitForDeployment();
  deployments.Lottery = {
    address: await lottery.getAddress(),
    args: lotteryArgs,
  };
  console.log("Lottery deployed to:", deployments.Lottery.address);

  // Save deployment information
  const deploymentsPath = path.join(__dirname, "..", "deployments.json");
  fs.writeFileSync(
    deploymentsPath,
    JSON.stringify(
      deployments,
      (key, value) => (typeof value === "bigint" ? value.toString() : value),
      2
    )
  );
  console.log("Deployment information saved to", deploymentsPath);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
