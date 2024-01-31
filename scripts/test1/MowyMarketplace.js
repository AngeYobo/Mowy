const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Mowy Marketplace and NFT Core Integration Tests", function () {
    let MowyNFTCore, MowyMarketplace;
    let nftCore, marketplace;
    let owner, artist, buyer;
    let listingFee; 

    before(async function () {
        [owner, artist, buyer] = await ethers.getSigners();
        MowyNFTCore = await ethers.getContractFactory("MowyNFTCore");
        MowyMarketplace = await ethers.getContractFactory("MowyMarketplace");

        nftCore = await MowyNFTCore.deploy("baseURI");
        // Initialize the listingFee variable
        listingFee = ethers.utils.parseEther("0.01"); // Example fee, adjust as necessary
        
        marketplace = await MowyMarketplace.deploy(nftCore.address, listingFee);
    });

    // Additional setup if needed
    it("Should mint an NFT from the NFT Core", async function () {
        await nftCore.connect(artist).mint(artist.address, 1, "0x00");
        expect(await nftCore.balanceOf(artist.address, 1)).to.equal(1);
    });

    // Listing NFTs on Marketplace
    it("Should list an NFT on the Marketplace", async function () {
        // Assuming there's a list function in the marketplace
        await marketplace.connect(artist).list(1, ethers.utils.parseEther("1"));
        // Validate the listing
    });

    // Buying NFTs from Marketplace:
    it("Should allow buying an NFT from the Marketplace", async function () {
        // Assuming a buy function exists in the marketplace
        await marketplace.connect(buyer).buy(1, { value: ethers.utils.parseEther("1") });
        // Check the balance of buyer and artist
    });

    // Fee and Royalty Handling:
    it("Should handle fees and royalties correctly", async function () {
        // Test fee deductions and royalty payments
    });
    
    // Access Control Tests:
    it("Should respect access control rules", async function () {
        // Test that only roles with MINTER_ROLE can mint NFTs, etc.
    });
    
    
});
