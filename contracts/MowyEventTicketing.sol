// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MowyNFTCore.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MowyEventTicketing is AccessControl, ERC1155, ERC1155Holder {
    // Define roles
    bytes32 public constant EVENT_MANAGER_ROLE = keccak256("EVENT_MANAGER_ROLE");
    bytes32 public constant EVENT_ORGANIZER_ROLE = keccak256("EVENT_ORGANIZER_ROLE");

    // Reference to MowyNFTCore contract for ticketing
    MowyNFTCore private nftCore;

    // Struct for event details
    struct Event {
        uint256 id;
        string name;
        uint256 date;
        uint256 ticketPrice;
        bool isActive;
        bool hasSeating;
        uint256 totalSeats;
        uint256 seatsPerRow;
        uint256 ticketsSold;
        uint256 totalTickets; // Add this field
    }

    // Mapping from event ID to event details
    mapping(uint256 => Event) private events;

    // Custom counter for event IDs
    uint256 private _eventIdCounter;

    struct EventDetails {
        uint256 id;
        string name;
        uint256 date;
        bool isActive;
        bool hasSeating;
        uint256 totalSeats;
        uint256 seatsPerRow;
        uint256 ticketsSold;
        uint256 totalTickets;
    }

    struct Seat {
        uint256 row;
        uint256 number;
        bool isOccupied;
        address occupant;
    }
    mapping(uint256 => mapping(uint256 => Seat)) public eventSeats; // eventId => seatId => Seat

    // Emit events in respective functions
    event EventCreated(uint256 eventId, string name, string description, uint256 date, uint256 ticketPrice, uint256 totalTickets);
    event TicketPurchased(uint256 eventId, address buyer, uint256 amount);
    event SeatOccupancyUpdated(uint256 indexed eventId, uint256 indexed seatId, bool isOccupied);
    event TicketTransferred(uint256 indexed eventId, uint256 indexed seatId, address from, address to);
    event SeatDetails(uint256 indexed eventId, uint256 indexed seatId, uint256 row, uint256 number);
    event SeatedTicketTransferred(uint256 indexed eventId, uint256 indexed seatId, address indexed from, address to);
    event SeatedTicketReceived(uint256 indexed eventId, uint256 indexed seatId, address indexed to);

    // Constructor
    constructor(address nftCoreAddress, string memory uri) ERC1155(uri) {
        require(nftCoreAddress != address(0), "MowyEventTicketing: Invalid NFT core address");
        nftCore = MowyNFTCore(nftCoreAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(EVENT_MANAGER_ROLE, msg.sender);
        _eventIdCounter = 1;
    }

    // Function to create a new event
    function createEvent(
        uint256 eventId,
        string memory name,
        string memory description,
        uint256 date,
        bool hasSeating,
        uint256 totalSeats,
        uint256 seatsPerRow,
        uint256 ticketPrice,
        uint256 totalTickets
    ) public onlyRole(EVENT_ORGANIZER_ROLE) {
        events[eventId] = Event({
        id: eventId,
        name: name,
        date: date,
        ticketPrice: ticketPrice,
        isActive: true,
        hasSeating: hasSeating,
        totalSeats: totalSeats,
        seatsPerRow: seatsPerRow,
        ticketsSold: 0,
        totalTickets: totalTickets
        });

        if (hasSeating) {
        initializeSeats(eventId, totalSeats, seatsPerRow);
        }
        // Emit event creation event...
        emit EventCreated(eventId, name, description, date, ticketPrice, totalTickets);
    }

    // Function to initialize seats for an event
    function initializeSeats(
        uint256 eventId,
        uint256 totalSeats,
        uint256 seatsPerRow
    ) internal {
        uint256 seatId = 1;
        for (uint256 i = 0; i < totalSeats; i++) {
            uint256 row = (i / seatsPerRow) + 1;
            uint256 number = (i % seatsPerRow) + 1;

            eventSeats[eventId][seatId] = Seat({
                row: row,
                number: number,
                isOccupied: false,
                occupant: address(0)
            });

            seatId++;
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC1155, ERC1155Holder) returns (bool) {
        return AccessControl.supportsInterface(interfaceId) || ERC1155.supportsInterface(interfaceId) || ERC1155Holder.supportsInterface(interfaceId);
    }

    // Function to mint event tickets
    function mintTicket(
        uint256 eventId,
        uint256 seatId,
        address recipient
    ) public onlyRole(EVENT_ORGANIZER_ROLE) {
        require(events[eventId].hasSeating, "Event does not have seating");
        require(!eventSeats[eventId][seatId].isOccupied, "Seat is already occupied");

        // Mint the ticket
        _mint(recipient, eventId, 1, ""); // Consider using a URI for ticket metadata

        // Mark the seat as occupied
        eventSeats[eventId][seatId].isOccupied = true;

        // Emit ticket minted event...
        emit SeatOccupancyUpdated(eventId, seatId, true);
    }

    // Function to mint tickets for events without seating
    function mintGeneralAdmissionTicket(
        uint256 eventId,
        address recipient
    ) public onlyRole(EVENT_ORGANIZER_ROLE) {
        require(!events[eventId].hasSeating, "Event has designated seating");

        // Mint the ticket
        _mint(recipient, eventId, 1, ""); // Consider using a URI for ticket metadata

        // Emit ticket minted event...
    }

    // Function to check if a seat is occupied
    function isSeatOccupied(uint256 eventId, uint256 seatId) public view returns (bool) {
        require(events[eventId].hasSeating, "Event does not have seating");
        return eventSeats[eventId][seatId].isOccupied;
    }

    // Function to get seat details
    function getSeatDetails(uint256 eventId, uint256 seatId) public returns (Seat memory) {
        require(events[eventId].hasSeating, "Event does not have seating");

        emit SeatDetails(eventId, seatId, eventSeats[eventId][seatId].row, eventSeats[eventId][seatId].number);
        return eventSeats[eventId][seatId];
    }

    // Overriding the safeTransferFrom function for seated events
    function safeTransferFrom(
        address from,
        address to,
        uint256 eventId,
        uint256 amount,
        bytes memory data
    ) public override {
        require(amount == 1, "Can only transfer one ticket at a time");

        uint256 seatId = findSeatIdByOccupant(from, eventId);
        require(seatId != 0, "Seat ID not found for the ticket");   

        if (events[eventId].hasSeating) {
            // Logic for transferring a seated ticket
            transferSeatedTicket(from, to, eventId);
        } else {
            // Logic for transferring a general admission ticket
            super.safeTransferFrom(from, to, eventId, amount, data);
        }

        emit TicketTransferred(eventId, seatId, from, to);
    }

    // Function to retrieve the total number of seats for a specific event
    function getTotalSeatsForEvent(uint256 eventId) internal view returns (uint256) {
        require(events[eventId].id != 0, "Event does not exist");
        return events[eventId].totalSeats;
    }
    /**
     * @dev Internal function to transfer a seated ticket.
     * @param from Address of the current ticket holder.
     * @param to Address of the new ticket holder.
     * @param eventId ID of the event for which the ticket is valid.
     */
    function transferSeatedTicket(address from, address to, uint256 eventId) internal {
        uint256 seatId = findSeatIdByOccupant(from, eventId);
        require(seatId != 0, "Ticket not found for this user");

        Seat storage seat = eventSeats[eventId][seatId];
        require(seat.isOccupied && seat.occupant == from, "No occupied seat found for this user in this event");

        // Update the seat with new occupant
        seat.occupant = to;

        // Emit event for ticket transfer
        emit SeatedTicketTransferred(eventId, seatId, from, to);
    }
     
    /**
     * @dev Helper function to find a seat by occupant address.
     * @param occupant Address of the occupant to search for.
     * @param eventId ID of the event.
     * @return seatId ID of the seat, returns 0 if not found.
     */
    function findSeatIdByOccupant(address occupant, uint256 eventId) internal view returns (uint256 seatId) {
        // Assuming a reasonable number of seats to iterate over
        uint256 totalSeats = getTotalSeatsForEvent(eventId); // Define this function based on your contract's logic
        for (uint256 i = 1; i <= totalSeats; i++) {
            if (eventSeats[eventId][i].occupant == occupant) {
                return i;
            }
        }
        return 0;
    }    

    // Function to purchase tickets for an event
    function purchaseTicket(uint256 eventId, uint256 amount) public payable {
        require(events[eventId].isActive, "MowyEventTicketing: Event is not active");
        require(events[eventId].ticketsSold + amount <= events[eventId].totalTickets, "MowyEventTicketing: Not enough tickets");
        require(msg.value == amount * events[eventId].ticketPrice, "MowyEventTicketing: Incorrect payment");

        events[eventId].ticketsSold += amount;
        nftCore.mint(msg.sender, amount, ""); // Minting NFT tickets

        emit TicketPurchased(eventId, msg.sender, amount);
    }

    // Additional functions like updateEvent, cancelEvent, etc., can be added as needed.

    // Custom internal function to increment event ID counter
    function _incrementEventId() internal {
        _eventIdCounter += 1;
    }

    // Getters for event details and ticket availability
    function getEventDetails(uint256 eventId) public view returns (EventDetails memory) {
        require(events[eventId].isActive, "MowyEventTicketing: Event does not exist");

        Event memory evnt = events[eventId];
        EventDetails memory eventDetails = EventDetails({
            id: evnt.id,
            name: evnt.name,
            date: evnt.date,
            isActive: evnt.isActive,
            hasSeating: evnt.hasSeating,
            totalSeats: evnt.totalSeats,
            seatsPerRow: evnt.seatsPerRow,
            ticketsSold: evnt.ticketsSold,
            totalTickets: evnt.totalTickets
        });

        return eventDetails;
    }

    
    function availableTickets(uint256 eventId) public view returns (uint256) {
        require(events[eventId].isActive, "MowyEventTicketing: Event does not exist");
        return events[eventId].totalTickets - events[eventId].ticketsSold;
    }

    // ... Other relevant functions
}
