pragma solidity ^0.5.0;

    /*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    address public owner;

    uint   PRICE_TICKET = 100 wei;

    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint public idGenerator;

    /*
        Define an Event struct, similar to the V1 of this contract.
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */

    struct Event
    {
      string description;
      string website;
      uint totalTickets;
      uint sales;
      mapping(address => uint256) buyers;
      bool isOpen;
    }

    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */

    mapping(uint256 => Event) public events;

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance, uint eventId);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier onlyOwner()
    {
      require(msg.sender == owner);
      _;
    }

    modifier whenOpen(uint _eventId)
    {
      require(events[_eventId].isOpen, "This event is not open");
      _;
    }

    constructor ()
    public
    {
      owner = msg.sender;
    }

    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */

    function addEvent(string memory _description, string memory _website, uint256 _numOfTickets)
    public
    onlyOwner
    returns(uint eventId)
    {

      Event memory newEvent = Event(_description, _website, _numOfTickets, 0, true);
      // Event memory newEvent;
      // newEvent.description = _description;
      // newEvent.website = _url;
      // newEvent.totalTickets = _numOfTickets;
      // newEvent.isOpen = true;
      eventId = idGenerator++;
      events[eventId] = newEvent;
      emit LogEventAdded(_description, _website, _numOfTickets, eventId);
      return eventId;
    }
    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. tickets available
            4. sales
            5. isOpen
    */
    function readEvent(uint _eventId)
    public
    view
    returns(string memory description, string memory website, uint ticketsAvailable, uint sales, bool isOpen)
    {
      description = events[_eventId].description;
      website = events[_eventId].website;
      ticketsAvailable = events[_eventId].totalTickets;
      sales = events[_eventId].sales;
      isOpen = events[_eventId].isOpen;
    }

    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */

    function buyTickets(uint _eventId, uint _numOfTickets)
    public
    payable
    whenOpen(_eventId)
    {
      require(msg.value >= (_numOfTickets * PRICE_TICKET));
      require(_numOfTickets <= (events[_eventId].totalTickets - events[_eventId].sales));
      events[_eventId].buyers[msg.sender] += _numOfTickets;
      events[_eventId].totalTickets - _numOfTickets;
      events[_eventId].sales += _numOfTickets;
      emit LogBuyTickets(msg.sender, _eventId, _numOfTickets);
    }
    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */

    function getRefund(uint _eventId)
    public
    whenOpen(_eventId)
    {
     require(events[_eventId].buyers[msg.sender] > 0);
     uint numOfTickets = events[_eventId].buyers[msg.sender];
     events[_eventId].totalTickets += numOfTickets;
     events[_eventId].sales -= numOfTickets;
     events[_eventId].buyers[msg.sender] = 0;
     uint refund = numOfTickets * PRICE_TICKET;
     (bool success, ) = msg.sender.call.value(refund)("");
     require(success, "Transfer failed.");
     emit LogGetRefund(msg.sender, _eventId, numOfTickets);
    }

    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */

    function getBuyerNumberTickets(uint _eventId)
    public
    view
    returns(uint)
    {
      return events[_eventId].buyers[msg.sender];
    }

    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */

    function endSale(uint _eventId)
    public
    onlyOwner
    {
      events[_eventId].isOpen = false;
    uint contractBalance = address(this).balance;
    (bool success, ) = msg.sender.call.value(contractBalance)("");
     require(success, "Transfer failed.");
     emit LogEndSale(msg.sender, contractBalance, _eventId);
    }
}
