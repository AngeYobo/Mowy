// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MowyNFTCore.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";


contract MowyMarketplace is Context, AccessControl, ReentrancyGuard, ERC1155Holder {
    // Define the roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");

    // Reference to the NFT contract
    MowyNFTCore private nftContract;
    address public nftContractAddress;
    address private feeRecipient;

    // A pause mechanism for emergency use.
    bool public isPaused = false;

    // Define events for transparency and tracking.
    event Listed(uint256 tokenId, uint256 price, address seller);
    event Sold(uint256 tokenId, uint256 price, address seller, address buyer);
    event PriceChanged(uint256 tokenId, uint256 newPrice);
    event RoyaltyInfoUpdated(uint256 indexed tokenId, address recipient, uint256 percentage);
    event RoyaltyPaid(uint256 indexed tokenId, address recipient, uint256 amount);
    event MarketplaceFeeUpdated(uint256 fee);
    event NFTContractAddressUpdated(address newAddress);
    event MarketplacePaused(bool isPaused);
    event EmergencyWithdraw(address admin, uint256 amount);
    event ContractInitialized(address sender, address contractAddress, address nftContract);
    event NFTListed(uint256 tokenId, address seller, uint256 price);
    event NFTPurchased(uint256 tokenId, address seller, address buyer, uint256 price);
    event NewHighestBid(uint256 indexed tokenId, address indexed bidder, uint256 bidAmount);
    event BidAccepted(uint256 tokenId, address bidder);
    event AuctionConcluded(uint256 tokenId, address highestBidder, uint256 highestBid);

    // State variables
    mapping(uint256 => Listing) public listings;
    mapping(uint256 => Bid) public highestBids;
    mapping(uint256 => RoyaltyInfo) public royalties;
    mapping(uint256 => Auction) public auctions;
    uint256 public constant initialFeePercentage = 200;
    uint256 public marketplaceFee; // Updated variable

    struct Listing {
        address seller;
        uint256 price;
        bool isListed;
    }

    struct Bid {
        address bidder;
        uint256 bidAmount;
    }

    struct RoyaltyInfo {
        address recipient;
        uint256 percentage;
    }

    struct Auction {
        address seller;
        bool active;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
    }

    uint256 public transactionFeePercentage;

    /**
     * @dev Overriding `supportsInterface` to handle conflict between `AccessControl` and `ERC1155Holder`.
     */
    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC1155Holder) returns (bool) {
        return AccessControl.supportsInterface(interfaceId) || ERC1155Holder.supportsInterface(interfaceId);
    }

    /**
     * @dev Constructor for MowyMarketplace.
     * @param _nftContract Address of the MowyNFTCore contract.
     */
    constructor(address _nftContract) {
        require(_nftContract != address(0), "Invalid NFT contract address");

        // Set the NFT contract reference
        nftContract = MowyNFTCore(_nftContract);
        // Setup the admin role
        _grantRole(ADMIN_ROLE, msg.sender);
        // Additional setup can be added here like
        _grantRole(CURATOR_ROLE, msg.sender);

        // Initialize fee structure
        transactionFeePercentage = initialFeePercentage;
        feeRecipient = msg.sender;

        // Initialize governance parameters if applicable
        // ...

        // Emit an event if necessary
        emit ContractInitialized(msg.sender, address(this), _nftContract);
    }

    function grantCuratorRole(address account) public onlyRole(ADMIN_ROLE) {
        grantRole(CURATOR_ROLE, account);
    }

    function revokeCuratorRole(address account) public onlyRole(ADMIN_ROLE) {
        revokeRole(CURATOR_ROLE, account);
    }

    // Functions for listing, buying, and bidding
    function listNFT(uint256 tokenId, uint256 price) public {
        require(IERC1155(nftContract).balanceOf(msg.sender, tokenId) > 0, "Not the owner");
        require(price > 0, "Price must be greater than zero");

        listings[tokenId] = Listing(msg.sender, price, true);
        emit NFTListed(tokenId, msg.sender, price);
    }

    // Functions for buying
    function buyNFT(uint256 tokenId) public payable nonReentrant {
        Listing memory listing = listings[tokenId];
        require(listing.isListed, "NFT not listed");
        require(msg.value == listing.price, "Incorrect value");

        // Transfer funds to seller
        payable(listing.seller).transfer(msg.value);

        // Transfer NFT to buyer
        IERC1155(nftContract).safeTransferFrom(listing.seller, msg.sender, tokenId, 1, "");

        // Update listing
        listings[tokenId].isListed = false;
        emit NFTPurchased(tokenId, listing.seller, msg.sender, listing.price);
    }

    // Functions for bidding
    function placeBid(uint256 tokenId) public payable {
        require(listings[tokenId].isListed, "NFT not listed for auction");
        require(msg.value > highestBids[tokenId].bidAmount, "Bid too low");

        // Refund previous highest bidder
        if (highestBids[tokenId].bidAmount > 0) {
            payable(highestBids[tokenId].bidder).transfer(highestBids[tokenId].bidAmount);
        }

        highestBids[tokenId] = Bid(msg.sender, msg.value);
        emit NewHighestBid(tokenId, msg.sender, msg.value);
    }

    function acceptBid(uint256 tokenId) public {
        require(msg.sender == listings[tokenId].seller, "Not the seller");
        require(highestBids[tokenId].bidAmount > 0, "No bids");

        // Transfer funds to seller
        payable(msg.sender).transfer(highestBids[tokenId].bidAmount);

        // Transfer NFT to highest bidder
        IERC1155(nftContract).safeTransferFrom(msg.sender, highestBids[tokenId].bidder, tokenId, 1, "");

        // Update listing and bid
        listings[tokenId].isListed = false;
        delete highestBids[tokenId];
        emit BidAccepted(tokenId, highestBids[tokenId].bidder);
    }

    // Functions for auction management
    function concludeAuction(uint256 tokenId) public {
        Auction storage auction = auctions[tokenId];
        require(auction.active, "Auction not active");
        require(block.timestamp >= auction.endTime, "Auction not ended");
        require(msg.sender == auction.seller || msg.sender == auction.highestBidder, "Unauthorized");

        auction.active = false;

        if (auction.highestBidder != address(0)) {
            // Transfer the NFT to the highest bidder
            IERC1155(nftContract).safeTransferFrom(auction.seller, auction.highestBidder, tokenId, 1, "");

            // Transfer the funds to the seller
            payable(auction.seller).transfer(auction.highestBid);
        } else {
            // No bids, return NFT to the seller
        }

        emit AuctionConcluded(tokenId, auction.highestBidder, auction.highestBid);
    }


    // Functions for royalty distribution
    function setRoyaltyInfo(uint256 tokenId, address recipient, uint256 percentage) public {
        require(hasRole(ADMIN_ROLE, msg.sender) || hasRole(CURATOR_ROLE, msg.sender), "Unauthorized");
        require(percentage <= 10000, "Invalid percentage"); // Max 100% in basis points
        
        royalties[tokenId] = RoyaltyInfo(recipient, percentage);
        emit RoyaltyInfoUpdated(tokenId, recipient, percentage);
    }

    // Calculating and Distributing Royalties
    function _distributeRoyalties(uint256 tokenId, uint256 saleAmount) internal {
        RoyaltyInfo memory royalty = royalties[tokenId];
        if (royalty.recipient != address(0) && royalty.percentage > 0) {
            uint256 royaltyAmount = (saleAmount * royalty.percentage) / 10000;
            require(royaltyAmount < saleAmount, "Royalty exceeds sale amount");

            payable(royalty.recipient).transfer(royaltyAmount);
            emit RoyaltyPaid(tokenId, royalty.recipient, royaltyAmount);
        }
    }

    // Royalty Payout during Sales

    function executeSale(uint256 tokenId, uint256 saleAmount) public payable {
        // ... sale logic (ownership transfer, payment handling, etc.) ...

        _distributeRoyalties(tokenId, saleAmount);
    }

    // Admin functions (Set Marketplace Fee, Update Contract Addresses, Pause/Unpause Contract, Role Management, Emergency Withdraw)
    function setMarketplaceFee(uint256 _fee) public onlyRole(ADMIN_ROLE) {
        require(_fee <= 10000, "Invalid fee");
        marketplaceFee = _fee;
        emit MarketplaceFeeUpdated(_fee);
    }

    function updateNFTContractAddress(address _newAddress) public onlyRole(ADMIN_ROLE) {
        require(_newAddress != address(0), "Invalid address");
        nftContractAddress = _newAddress;
        emit NFTContractAddressUpdated(_newAddress);
    }

    function togglePause() public onlyRole(ADMIN_ROLE) {
        isPaused = !isPaused;
        emit MarketplacePaused(isPaused);
    }

    function grantRole(bytes32 role, address account) public override onlyRole(getRoleAdmin(role)) {
        super.grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public override onlyRole(getRoleAdmin(role)) {
        super.revokeRole(role, account);
    }

    function emergencyWithdraw() public onlyRole(ADMIN_ROLE) {
        uint256 contractBalance = address(this).balance;
        payable(msg.sender).transfer(contractBalance);
        emit EmergencyWithdraw(msg.sender, contractBalance);
    }

    // ...other functions as needed
}
            