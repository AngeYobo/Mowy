// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
    // Deploying the MowyNFTCore contract
    const MowyNFTCore = await hre.ethers.getContractFactory("MowyNFTCore");
    const mowyNFTCore = await MowyNFTCore.deploy("https://example.com/");

    await mowyNFTCore.deployed();

    console.log(`MowyNFTCore deployed to: ${mowyNFTCore.address}`);

    // Set up roles
    const [deployer] = await hre.ethers.getSigners();
    const ADMIN_ROLE = await mowyNFTCore.ADMIN_ROLE();
    const MINTER_ROLE = await mowyNFTCore.MINTER_ROLE();

    // Grant ADMIN_ROLE and MINTER_ROLE to the deployer for demonstration
    // In a production environment, consider assigning these roles appropriately
    await mowyNFTCore.grantRole(ADMIN_ROLE, deployer.address);
    await mowyNFTCore.grantRole(MINTER_ROLE, deployer.address);

    console.log(`Roles granted to deployer (${deployer.address})`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
