const hre = require("hardhat");

async function main() {
  const baseURI = "ipfs://bafybeig5n4vsb5lt3enlvjyy34kgmhug6pph5wpad7txi5rl3n2oc6plri/";
  const hiddenURI = "ipfs://bafybeig5n4vsb5lt3enlvjyy34kgmhug6pph5wpad7txi5rl3n2oc6plri/";
  const royaltyBips = 500; // 5%
  const maxSupply = 1000;

  const Helivault = await hre.ethers.getContractFactory("HelivaultNFT");
  const contract = await Helivault.deploy(baseURI, hiddenURI, royaltyBips, maxSupply);
  await contract.waitForDeployment();

  const address = await contract.getAddress();
  console.log("✅ HelivaultNFT deployed to:", address);
}

main().catch((error) => {
  console.error("❌ Deployment failed:", error);
  process.exit(1);
});
