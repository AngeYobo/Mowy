// Import necessary libraries and contracts
const { expect } = require("chai");
const { ethers } = require("hardhat");


describe("MowyNFTCore Test Suite", function () {
    let MowyNFTCore, mowyNFTCore, owner, minter, admin, recipient;

    beforeEach(async function () {
        [owner, minter, admin, recipient] = await ethers.getSigners();
        MowyNFTCore = await ethers.getContractFactory("MowyNFTCore");
        mowyNFTCore = await MowyNFTCore.deploy("https://example.com/");
        

        await mowyNFTCore.grantRole(await mowyNFTCore.MINTER_ROLE(), minter.address);
        await mowyNFTCore.grantRole(await mowyNFTCore.ADMIN_ROLE(), admin.address);
    });

    it("should assign roles correctly", async function () {
        
        expect(await mowyNFTCore.hasRole(await mowyNFTCore.MINTER_ROLE(), minter.address)).to.be.true;
        expect(await mowyNFTCore.hasRole(await mowyNFTCore.ADMIN_ROLE(), admin.address)).to.be.true;
    });

    //it("should mint tokens correctly", async function () {
        //const tokenIdBefore = await mowyNFTCore.tokenIdCounter();
        
        // Use ethers.utils.arrayify to create an empty bytes array
        //const emptyData = ethers.utils.arrayify("0x");
    
        //await mowyNFTCore.connect(minter).mint(recipient.address, 1, emptyData);
    
        //const expectedTokenId = tokenIdBefore.add(1);
        //const tokenIdAfter = await mowyNFTCore.tokenIdCounter();
        //expect(tokenIdAfter).to.equal(expectedTokenId);
    
        //expect(await mowyNFTCore.balanceOf(recipient.address, expectedTokenId)).to.equal(1);
    //});
    

    //it("should handle URI correctly", async function () {
        //const tokenId = await mowyNFTCore.tokenIdCounter();
        //await mowyNFTCore.connect(minter).mint(recipient.address, 1, []);
    
        //const expectedUri = `https://example.com/${tokenId.toString()}`;
        //expect(await mowyNFTCore.uri(tokenId)).to.equal(expectedUri);
    //});

    //it("should not allow unauthorized minting", async function () {
        //await expect(mowyNFTCore.connect(recipient).mint(recipient.address, 1, []))
            //.to.be.reverted;
    //});

    it("should allow admin to change URI", async function () {
        const newUri = "https://newexample.com/";
        await mowyNFTCore.connect(admin).setURI(newUri);
        expect(await mowyNFTCore.baseURI()).to.equal(newUri);
    });

    // Add more tests as needed to cover other functionalities and edge cases
});
