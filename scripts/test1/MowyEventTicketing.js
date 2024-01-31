const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MowyEventTicketing Tests", function () {
  let mowyNFTCore, mowyEventTicketing;
  let deployer, otherAccount;

  beforeEach(async function () {
    [deployer, otherAccount] = await ethers.getSigners();

    // Deploy MowyNFTCore
    const MowyNFTCore = await ethers.getContractFactory("MowyNFTCore");
    mowyNFTCore = await MowyNFTCore.deploy(/* constructor arguments for MowyNFTCore */);
    await mowyNFTCore.deployed();

    // Deploy MowyEventTicketing with the address of MowyNFTCore
    const MowyEventTicketing = await ethers.getContractFactory("MowyEventTicketing");
    mowyEventTicketing = await MowyEventTicketing.deploy(mowyNFTCore.address);
    await mowyEventTicketing.deployed();
  });

  // Your tests here...
});
