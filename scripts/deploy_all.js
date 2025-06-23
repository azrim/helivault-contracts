// scripts/deploy_all.js

const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // --- Deployment Configuration ---
  const royaltyReceiver = deployer.address; // The address that will receive royalties
  const royaltyFeeNumerator = 500; // 5% royalty
  const tokenURI = "ipfs://bafybeih3lbjbvfspg4y4fjjxwizfjcmgav2gnepxu6zs3svfuniefqhruu"; // Replace with your single metadata file CID

  // Deploy HelivaultToken
  console.log("\nDeploying HelivaultToken contract...");
  const HelivaultToken = await ethers.getContractFactory("HelivaultToken");
  const hlvToken = await HelivaultToken.deploy();
  await hlvToken.waitForDeployment();
  const hlvTokenAddress = await hlvToken.getAddress();
  console.log(`✅ HelivaultToken deployed to: ${hlvTokenAddress}`);

  // Deploy QuantumRelics NFT
  console.log("\nDeploying QuantumRelics contract...");
  const QuantumRelics = await ethers.getContractFactory("QuantumRelics");
  const quantumRelics = await QuantumRelics.deploy(
    hlvTokenAddress,
    royaltyReceiver,
    royaltyFeeNumerator
  );
  await quantumRelics.waitForDeployment();
  const nftAddress = await quantumRelics.getAddress();
  console.log(`✅ QuantumRelics NFT deployed to: ${nftAddress}`);

  // --- Post-Deployment Configuration ---
  console.log("\nConfiguring QuantumRelics contract...");
  
  // Set the single token URI for the entire collection
  await quantumRelics.setTokenURI(tokenURI);
  console.log("-> Token URI set to:", tokenURI);
  
  // Start the sale in a state
  await quantumRelics.setSaleState(2); // 0 = Paused, 1 = Presale, 2 = Public
  console.log("-> Sale state set to Public.");

  console.log("\n🚀 Deployment and configuration complete! 🚀");
}

main().catch((error) => {
  console.error("❌ Deployment failed:", error);
  process.exit(1);
});