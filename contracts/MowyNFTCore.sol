// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title MowyNFTCore
 * @dev Implementation of a multi-token ERC1155 contract for the Mowy Platform.
 */
contract MowyNFTCore is ERC1155, AccessControl, ERC1155Burnable, ERC1155Supply {
    // Role definitions for minting and managing tokens
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant EVENT_ORGANIZER_ROLE = keccak256("EVENT_ORGANIZER_ROLE");
    // Token ID management using a simple counter
    uint256 private _tokenIdCounter;

    // Token URI prefix
    string private _uriPrefix;

    // Event for logging metadata updates
    event MetadataUpdated(uint256 indexed tokenId, string uri);    
    
    /**
     * @dev Constructor function
     * @param uriPrefix_ Initial base URI for metadata
     */
    constructor(string memory uriPrefix_) ERC1155(uriPrefix_) {
        _uriPrefix = uriPrefix_;

        // Setup roles and initial token ID
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(EVENT_ORGANIZER_ROLE, msg.sender); // Granting the role to the deployer
        _grantRole(MINTER_ROLE, msg.sender);
        _tokenIdCounter = 1; // Starting from 1, adjust as needed

    }
    
    /**
     * @dev Override for _update to resolve ambiguity between base contracts
     */
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values) internal override(ERC1155, ERC1155Supply) {
        super._update(from, to, ids, values);
    }

    /**
     * @dev Override for supportsInterface to resolve ambiguity between base contracts
     */
    function supportsInterface(bytes4 interfaceId) 
        public view virtual override(AccessControl, ERC1155) 
        returns (bool) 
    {
        return AccessControl.supportsInterface(interfaceId) || ERC1155.supportsInterface(interfaceId);
    }

    /**
     * @dev Creates a new token type and assigns it to an address
     * @param to address of the first owner of the token
     * @param amount quantity of the token to create
     * @param data data to pass if receiver is a contract
     */
    function mint(address to, uint256 amount, bytes memory data)
        public
        onlyRole(MINTER_ROLE)
    {
        uint256 tokenId = _tokenIdCounter;
        _mint(to, tokenId, amount, data);
        _tokenIdCounter += 1;

        emit MetadataUpdated(tokenId, uri(tokenId));
    }

    /**
     * @dev Sets a new URI for all token types
     * @param newUriPrefix New base URI to be set
     */
    function setURI(string memory newUriPrefix) public onlyRole(ADMIN_ROLE) {
        _setURI(newUriPrefix);
        _uriPrefix = newUriPrefix;
        emit URI(newUriPrefix, 0); // Emit the URI event with the new URI prefix and 0 to indicate a global change
    }

    /**
     * @dev Returns the base URI set for the tokens.
     */
    function baseURI() public view returns (string memory) {
        return _uriPrefix;
    }

    /**
     * @dev Returns the URI for a token type.
     * @param tokenId uint256 ID of the token type
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        require(exists(tokenId), "MowyNFTCore: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI(), Strings.toString(tokenId)));
    }

    function tokenIdCounter() public view returns (uint256) {
        return _tokenIdCounter;
    }
    

}

