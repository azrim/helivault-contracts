const fs = require("fs");
const path = require("path");
const chalk = require("chalk");
const hre = require("hardhat");

async function main() {
  console.log(chalk.yellow("============================================================"));
  console.log(chalk.yellow("        Verification Input Extractor Script        "));
  console.log(chalk.yellow("============================================================\n"));

  const readline = require("readline").createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  // 1. Find and list available contracts
  const contractsPath = path.resolve(__dirname, "..", "artifacts", "contracts");
  let contractNames = [];

  try {
    const contractFolders = fs.readdirSync(contractsPath, { withFileTypes: true })
      .filter(dirent => dirent.isDirectory() && dirent.name.endsWith(".sol"))
      .map(dirent => dirent.name);

    for (const folder of contractFolders) {
      const files = fs.readdirSync(path.join(contractsPath, folder));
      const contractName = files.find(file => file.endsWith(".json") && !file.endsWith(".dbg.json"));
      if (contractName) {
        contractNames.push(path.basename(contractName, ".json"));
      }
    }

    if (contractNames.length === 0) {
      throw new Error("No compiled contracts found. Please run 'npx hardhat compile' first.");
    }

  } catch (error) {
    console.error(chalk.red.bold("\n❌ Error finding contracts:"), error.message);
    process.exit(1);
  }

  console.log(chalk.cyan.bold("Available contracts to verify:"));
  contractNames.forEach((name, index) => {
    console.log(`  ${chalk.yellow(index + 1)}. ${name}`);
  });
  console.log("");

  // 2. Prompt user to select a contract
  const selection = await new Promise((resolve) => {
    readline.question(
      chalk.blue.bold("Enter the number of the contract to verify: "),
      (num) => resolve(num)
    );
  });

  const selectedIndex = parseInt(selection, 10) - 1;
  if (isNaN(selectedIndex) || selectedIndex < 0 || selectedIndex >= contractNames.length) {
    console.error(chalk.red.bold("\n❌ Error: Invalid selection. Please enter a valid number from the list."));
    readline.close();
    process.exit(1);
  }

  const contractName = contractNames[selectedIndex];

  // 3. Prompt for the contract address
  const contractAddress = await new Promise((resolve) => {
    readline.question(
      chalk.blue.bold(`Enter the deployed address for ${chalk.yellow(contractName)}: `),
      (addr) => {
        readline.close();
        resolve(addr);
      }
    );
  });

  // 4. Validate the address
  if (!hre.ethers.isAddress(contractAddress)) {
    console.error(chalk.red.bold(`\n❌ Error: Invalid address provided: '${contractAddress}'`));
    process.exit(1);
  }

  console.log(chalk.blue.bold(`\n▶️  Generating verification files for ${contractName} at: ${contractAddress}\n`));

  const buildInfoDir = path.resolve(__dirname, "..", "artifacts", "build-info");
  const outputDir = path.resolve(__dirname, "..", "output");

  // 5. Clean and create the output directory
  try {
    if (fs.existsSync(outputDir)) {
      fs.rmSync(outputDir, { recursive: true, force: true });
    }
    fs.mkdirSync(outputDir, { recursive: true });
    console.log(chalk.cyan(`   Output directory cleaned and created at: ${outputDir}`));
  } catch (error) {
      console.error(chalk.red.bold("\n❌  Error managing output directory:"), error.message);
      process.exit(1);
  }

  try {
    const files = fs.readdirSync(buildInfoDir);
    let latestBuildFile = "";
    let latestMtime = 0;

    for (const file of files) {
      if (file.endsWith(".json")) {
        const filePath = path.join(buildInfoDir, file);
        const stats = fs.statSync(filePath);
        if (stats.mtimeMs > latestMtime) {
          latestMtime = stats.mtimeMs;
          latestBuildFile = filePath;
        }
      }
    }

    if (!latestBuildFile) {
      throw new Error("No build-info file found. Please compile your contract first with 'npx hardhat compile'");
    }

    console.log(chalk.cyan(`   Found latest build file: ${path.basename(latestBuildFile)}`));

    const buildInfo = JSON.parse(fs.readFileSync(latestBuildFile, "utf8"));
    
    // 6. Generate and save the verify-input.json
    const verificationInput = buildInfo.input;
    const outputJsonPath = path.join(outputDir, `${contractName}-verify-input.json`);
    fs.writeFileSync(outputJsonPath, JSON.stringify(verificationInput, null, 2));

    console.log(chalk.green.bold("\n✅  Successfully created verification input file!"));
    console.log(chalk.cyan("   File saved to: ") + chalk.white.bold(outputJsonPath));

    // 7. Create the tutorial markdown file
    const explorerUrl = `https://explorer.helioschainlabs.org/address/${contractAddress}`;
    const compilerVersion = buildInfo.solcLongVersion;
    const tutorialContent = `
# How to Verify Your Smart Contract

This guide contains the specific details needed to verify the \`${contractName}\` smart contract on the Helios Explorer.

- **Contract Name:** \`${contractName}\`
- **Contract Address:** \`${contractAddress}\`
- **Explorer Link:** [${explorerUrl}](${explorerUrl})

### Verification Steps

1.  **Go to the Verification Page:**
    Navigate directly to your contract's "Verify and Publish" page on the [Helios Explorer](https://explorer.helioschainlabs.org). You can usually find this link under the "Contract" tab on your contract's main page.

2.  **Fill in the Verification Form:**
    *   **Contract Address:** \`${contractAddress}\` (this should be pre-filled).
    *   **Compiler Type:** Select **Solidity (Standard-Json-Input)**. This is the most important step.
    *   **Compiler Version:** Choose the exact compiler version used for this project: **v${compilerVersion}**.
    *   **License:** Select \`MIT License (MIT)\`, as specified in the source file.

3.  **Upload the JSON Input File:**
    Drag and drop the \`${path.basename(outputJsonPath)}\` file (located in this same \`output\` directory) into the upload area on the verification page.

4.  **Verify and Publish:**
    Click the "Verify and Publish" button. After a few moments, the page will refresh, and you should see a success message with a green checkmark.

Your contract is now verified!
`;

    const outputMdPath = path.join(outputDir, `${contractName}-verify-tutorial.md`);
    fs.writeFileSync(outputMdPath, tutorialContent.trim());
    
    console.log(chalk.green.bold("\n✅  Successfully created verification tutorial!"));
    console.log(chalk.cyan("   File saved to: ") + chalk.white.bold(outputMdPath));
    console.log(chalk.cyan("\n   All files are ready in the 'output' directory."));

  } catch (error) {
    console.error(chalk.red.bold("\n❌  Error creating verification input:"), error.message);
    process.exitCode = 1;
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});