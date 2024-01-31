const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MowyNFTCore 1", function () {
    let MowyNFTCore, mowyNFTCore, owner, admin, minter, user;

    beforeEach(async function () {
        [owner, admin, minter, user] = await ethers.getSigners();
        MowyNFTCore = await ethers.getContractFactory("MowyNFTCore");
        mowyNFTCore = await MowyNFTCore.deploy("initial_uri_prefix/");

        await mowyNFTCore.grantRole(await mowyNFTCore.MINTER_ROLE(), minter.address);
        await mowyNFTCore.grantRole(await mowyNFTCore.ADMIN_ROLE(), admin.address);
    });

        
    // ... Rest of the tests ...
    describe("Role Management", function () {
        it("should only allow admin to change URI", async function () {
            await expect(mowyNFTCore.connect(user).setURI("new_uri_prefix/")).to.be.reverted;
        });
    
        it("should only allow minter to mint tokens", async function () {
            await expect(mowyNFTCore.connect(user).mint(user.address, 1, "0x00")).to.be.reverted;
        });
    });

    describe("Token URI Generation", function () {
        it("should generate correct token URI", async function () {
            const tokenId = 1;
            await mowyNFTCore.connect(minter).mint(user.address, 1, "0x00");
            expect(await mowyNFTCore.uri(tokenId)).to.equal("initial_uri_prefix/1");
        });

        
    });

          
    describe("Rejection Scenarios", function () {
        it("should reject unauthorized minting", async function () {
            await expect(mowyNFTCore.connect(user).mint(user.address, 1, "0x00")).to.be.reverted;
        });
    
        it("should reject transfers of non-owned tokens", async function () {
            await mowyNFTCore.connect(minter).mint(user.address, 1, "0x00");
            await expect(mowyNFTCore.connect(minter).safeTransferFrom(user.address, admin.address, 1, 1, "0x00")).to.be.reverted;
        });
    });
    
    
    

    

    
    
    
    
    
    
    
    
            
});
