// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MowyNFTCore.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title MowyMintable
 * @dev Extends MowyNFTCore for specialized minting functionality.
 */
contract MowyMintable is MowyNFTCore, ReentrancyGuard {
    // Event for minting new NFTs
    event NFTMinted(uint256 indexed tokenId, address indexed recipient, uint256 amount, NFTType nftType);

    /**
     * @dev Constructor function
     * @param uriPrefix_ Initial base URI for metadata
     */
    constructor(string memory uriPrefix_) MowyNFTCore(uriPrefix_) {}

    /**
     * @dev Function to mint new NFTs
     * @param to Address to mint NFT to
     * @param amount Amount of NFTs to mint
     * @param nftType Type of NFT (Artwork, Music, Ticket, etc.)
     * @param data Additional data
     */
    function mintNFT(address to, uint256 amount, NFTType nftType, bytes memory data)
        public
        onlyRole(MINTER_ROLE)
        nonReentrant
    {
        require(to != address(0), "MowyMintable: mint to the zero address");
        require(amount > 0, "MowyMintable: mint amount should be positive");

        uint256 tokenId = tokenIdCounter();
        _mint(to, tokenId, amount, data);

        // Update NFT metadata (if needed)
        // _setNFTMetadata(tokenId, nftType, ...);

        emit NFTMinted(tokenId, to, amount, nftType);
    }

    // Additional minting functions (if needed)...
}

// Enum outside of contract for brevity
enum NFTType { Artwork, Music, Ticket }

