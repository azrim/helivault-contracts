// scripts/deploy.js

const { ethers } = require("hardhat");

async function main() {
  // --- Deployment Configuration ---

  // 1. Set your NFT's base and hidden metadata URIs
  const baseURI = "ipfs://QmXDGRYVtr6sVR8wToqmdLdLTRvGB16Uj8cnj9CFPPfwzo";
  const hiddenURI = "ipfs://QmXDGRYVtr6sVR8wToqmdLdLTRvGB16Uj8cnj9CFPPfwzo";

  // 2. Set the royalty percentage (e.g., 5% = 500)
  const royaltyBips = 500;

  // 3. Define the total supply of your NFT collection
  const maxSupply = 756;

  // 4. Set the mint price in HLS.
  // The HLS token has 18 decimals, just like Ethereum.
  const mintPriceInHLS = "0.0756"; // e.g., 0.5 HLS to mint one NFT

  // --- End of Configuration ---

  // Convert the HLS price to its smallest unit (wei)
  const initialMintPrice = ethers.parseEther(mintPriceInHLS);

  console.log("Deploying HelivaultCyphers contract to Helioschain...");
  console.log("Constructor arguments:");
  console.log(`  - Mint Price: ${mintPriceInHLS} HLS`);
  console.log("---------------------------------");

  // Get the contract factory for HelivaultCyphers
  const HelivaultCyphers = await ethers.getContractFactory("HelivaultCyphers");

  // Deploy the contract with the new constructor arguments
  const contract = await HelivaultCyphers.deploy(
    baseURI,
    hiddenURI,
    royaltyBips,
    maxSupply,
    initialMintPrice
  );

  // Wait for the deployment to be confirmed
  await contract.waitForDeployment();

  const contractAddress = await contract.getAddress();
  console.log(`✅ HelivaultCyphers deployed to: ${contractAddress} on the Helios network.`);
}

main().catch((error) => {
  console.error("❌ Deployment failed:", error);
  process.exit(1);
});