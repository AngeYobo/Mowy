const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MowyNFTCore Unit Test", function () {
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

describe("Unit Test 2", function () {
    let MowyNFTCore, mowyNFTCore, owner, admin, minter, user;

    beforeEach(async function () {
        [owner, admin, minter, user] = await ethers.getSigners();
        MowyNFTCore = await ethers.getContractFactory("MowyNFTCore");
        mowyNFTCore = await MowyNFTCore.deploy("initial_uri_prefix/");

        await mowyNFTCore.grantRole(await mowyNFTCore.MINTER_ROLE(), minter.address);
        await mowyNFTCore.grantRole(await mowyNFTCore.ADMIN_ROLE(), admin.address);
    });

    describe("Token Burning", function () {
        beforeEach(async function () {
            // Mint a token to the user before each burning test
            await mowyNFTCore.connect(minter).mint(user.address, 1, "0x00");
        });
    
        it("should allow token owners to burn their tokens", async function () {
            // User burns their token
            await expect(mowyNFTCore.connect(user).burn(user.address, 1, 1)).to.emit(mowyNFTCore, 'TransferSingle').withArgs(user.address, user.address, ethers.constants.AddressZero, 1, 1);
        });
    
        it("should prevent non-owners from burning tokens", async function () {
            // Attempt to burn a token that the minter does not own
            await expect(mowyNFTCore.connect(minter).burn(user.address, 1, 1))
                .to.be.revertedWith("ERC1155: caller is not owner nor approved");
        });
    });

    describe("Token Transfer", function () {
        it("should allow owners to transfer tokens", async function () {
            await mowyNFTCore.connect(minter).mint(user.address, 1, "0x00");
            await expect(mowyNFTCore.connect(user).safeTransferFrom(user.address, minter.address, 1, 1, "0x00")).to.emit(mowyNFTCore, 'TransferSingle').withArgs(user.address, user.address, minter.address, 1, 1);
        });

        it("should prevent non-owners from transferring tokens", async function () {
            await mowyNFTCore.connect(minter).mint(user.address, 1, "0x00");
            await expect(mowyNFTCore.connect(admin).safeTransferFrom(user.address, minter.address, 1, 1, "0x00")).to.be.revertedWith("ERC1155: caller is not owner nor approved");
        });
    });

    describe("Access Control", function () {

        it("should assign roles correctly", async function () {
        
            expect(await mowyNFTCore.hasRole(await mowyNFTCore.MINTER_ROLE(), minter.address)).to.be.true;
            expect(await mowyNFTCore.hasRole(await mowyNFTCore.ADMIN_ROLE(), admin.address)).to.be.true;
        });
        
        it("should allow admins to grant roles", async function () {            
            
            await expect(mowyNFTCore.connect(admin).grantRole(await mowyNFTCore.MINTER_ROLE(), user.address)).to.emit(mowyNFTCore, 'RoleGranted').withArgs(await mowyNFTCore.MINTER_ROLE(), user.address, admin.address);
        });

        it("should prevent non-admins from granting roles", async function () {
            await expect(mowyNFTCore.connect(user).grantRole(await mowyNFTCore.MINTER_ROLE(), minter.address)).to.be.revertedWith("AccessControl: sender must be an admin to grant");
        });

        it("should allow admins to revoke roles", async function () {
            await mowyNFTCore.connect(admin).grantRole(await mowyNFTCore.MINTER_ROLE(), user.address);
            await expect(mowyNFTCore.connect(admin).revokeRole(await mowyNFTCore.MINTER_ROLE(), user.address)).to.emit(mowyNFTCore, 'RoleRevoked').withArgs(await mowyNFTCore.MINTER_ROLE(), user.address, admin.address);
        });

        it("should prevent non-admins from revoking roles", async function () {
            await mowyNFTCore.connect(admin).grantRole(await mowyNFTCore.MINTER_ROLE(), user.address);
            await expect(mowyNFTCore.connect(user).revokeRole(await mowyNFTCore.MINTER_ROLE(), minter.address)).to.be.revertedWith("AccessControl: sender must be an admin to revoke");
        });
    });

    // ...Other relevant functions...
});


    

    
    
    
    
    
    
    
    
            
});
