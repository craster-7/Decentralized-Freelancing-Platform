const { ethers } = require("hardhat");

async function main() {
  console.log("🚀 Starting Decentralized Freelancing Platform deployment...\n");

  // Get the deployer account
  const [deployer] = await ethers.getSigners();
  console.log("📝 Deploying contracts with account:", deployer.address);
  
  // Check deployer balance
  const balance = await deployer.getBalance();
  console.log("💰 Account balance:", ethers.utils.formatEther(balance), "ETH\n");

  // Get the contract factory
  console.log("🔨 Compiling and preparing Project contract...");
  const Project = await ethers.getContractFactory("Project");

  // Deploy the contract
  console.log("⏳ Deploying Project contract...");
  const project = await Project.deploy();

  // Wait for deployment to complete
  await project.deployed();

  console.log("✅ Project contract deployed successfully!");
  console.log("📍 Contract address:", project.address);
  console.log("🔗 Transaction hash:", project.deployTransaction.hash);
  console.log("⛽ Gas used:", project.deployTransaction.gasLimit.toString());
  console.log("💸 Gas price:", ethers.utils.formatUnits(project.deployTransaction.gasPrice, "gwei"), "gwei\n");

  // Display contract information
  console.log("📋 Contract Information:");
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log("Contract Name: Decentralized Freelancing Platform");
  console.log("Contract Address:", project.address);
  console.log("Deployer Address:", deployer.address);
  console.log("Network:", (await ethers.provider.getNetwork()).name);
  console.log("Block Number:", await ethers.provider.getBlockNumber());
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");

  // Verify initial contract state
  console.log("🔍 Verifying initial contract state...");
  try {
    const owner = await project.owner();
    const projectCounter = await project.projectCounter();
    const platformFeePercent = await project.platformFeePercent();
    
    console.log("✓ Contract owner:", owner);
    console.log("✓ Initial project counter:", projectCounter.toString());
    console.log("✓ Platform fee percentage:", platformFeePercent.toString() + "%");
    console.log("✓ Contract balance:", ethers.utils.formatEther(await ethers.provider.getBalance(project.address)), "ETH");
  } catch (error) {
    console.log("❌ Error verifying contract state:", error.message);
  }

  // Display usage instructions
  console.log("\n📖 Next Steps:");
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log("1. Save the contract address for frontend integration");
  console.log("2. Verify the contract on block explorer (optional)");
  console.log("3. Test the contract functions:");
  console.log("   • Register as client: registerClient()");
  console.log("   • Register as freelancer: registerFreelancer()");
  console.log("   • Create projects: createProject()");
  console.log("   • Apply for projects: applyForProject()");
  console.log("4. Update your frontend/dApp configuration with the new address");
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");

  // Generate verification command for Etherscan
  const network = await ethers.provider.getNetwork();
  if (network.chainId !== 31337) { // Not local hardhat network
    console.log("🔍 Etherscan Verification Command:");
    console.log(`npx hardhat verify --network ${network.name} ${project.address}\n`);
  }

  // Save deployment info to file
  const deploymentInfo = {
    contractName: "Project",
    contractAddress: project.address,
    deployer: deployer.address,
    network: network.name,
    chainId: network.chainId,
    blockNumber: await ethers.provider.getBlockNumber(),
    transactionHash: project.deployTransaction.hash,
    gasUsed: project.deployTransaction.gasLimit.toString(),
    gasPrice: project.deployTransaction.gasPrice.toString(),
    deploymentTime: new Date().toISOString(),
    abi: Project.interface.format('json')
  };

  // Write deployment info to JSON file
  const fs = require('fs');
  const path = require('path');
  
  try {
    const deploymentsDir = path.join(__dirname, '..', 'deployments');
    if (!fs.existsSync(deploymentsDir)) {
      fs.mkdirSync(deploymentsDir, { recursive: true });
    }
    
    const fileName = `deployment-${network.name}-${Date.now()}.json`;
    const filePath = path.join(deploymentsDir, fileName);
    
    fs.writeFileSync(filePath, JSON.stringify(deploymentInfo, null, 2));
    console.log("💾 Deployment info saved to:", filePath);
  } catch (error) {
    console.log("⚠️  Could not save deployment info:", error.message);
  }

  console.log("\n🎉 Deployment completed successfully!");
  console.log("🌟 Your Decentralized Freelancing Platform is ready to use!");
  
  return {
    contract: project,
    address: project.address,
    deployer: deployer.address
  };
}

// Handle deployment errors
main()
  .then((result) => {
    console.log("\n✨ Deployment Summary:");
    console.log("Contract Address:", result.address);
    console.log("Deployer:", result.deployer);
    process.exit(0);
  })
  .catch((error) => {
    console.error("\n❌ Deployment failed:");
    console.error(error);
    process.exit(1);
  });

// Export for testing purposes
module.exports = main;
