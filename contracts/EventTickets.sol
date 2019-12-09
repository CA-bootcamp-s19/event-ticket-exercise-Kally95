pragma solidity ^0.5.0;

    /*
        The EventTickets contract keeps track of the details and ticket sales of one event.
     */

contract EventTickets {

    /*
        Create a public state variable called owner.
        Use the appropriate keyword to create an associated getter function.
        Use the appropriate keyword to allow ether transfers.
     */

    address payable public owner;

    uint TICKET_PRICE = 100 wei;

    /*
        Create a struct called "Event".
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */

    struct Event {
      string description;
      string website;
      uint totalTickets;
      uint sales;
      mapping(address => uint256) buyers;
      bool isOpen;
    }

    /*
        Define 3 logging events.
        LogBuyTickets should provide information about the purchaser and the number of tickets purchased.
        LogGetRefund should provide information about the refund requester and the number of tickets refunded.
        LogEndSale should provide infromation about the contract owner and the balance transferred to them.
    */

    Event myEvent;

    event LogBuyTickets(address indexed _buyer, uint indexed _ticketsBought);
    event LogGetRefund(address indexed _refunder, uint indexed _ticketsRefunded);
    event LogEndSale(address indexed _owner, uint indexed _balanceRecieved);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier onlyOwner {
      require(owner == msg.sender, "Only owner can call");
      _;
    }

    modifier onlyWhenOpen {
      require(myEvent.isOpen == true, "This event is not open");
      _;
    }

    /*
        Define a constructor.
        The constructor takes 3 arguments, the description, the URL and the number of tickets for sale.
        Set the owner to the creator of the contract.
        Set the appropriate myEvent details.
    */
    constructor(string memory _description, string memory _website, uint _totalTickets) public {
      owner = msg.sender;
      myEvent = Event(_description, _website, _totalTickets, 0, true);
    }
    /*
        Define a function called readEvent() that returns the event details.
        This function does not modify state, add the appropriate keyword.
        The returned details should be called description, website, uint totalTickets, uint sales, bool isOpen in that order.
    */
    function readEvent()
        public
        view
        returns(string memory description, string memory website, uint totalTickets, uint sales, bool isOpen)
    {
      description = myEvent.description;
      website = myEvent.website;
      totalTickets = myEvent.totalTickets;
      sales = myEvent.sales;
      isOpen = myEvent.isOpen;
    }

    /*
        Define a function called getBuyerTicketCount().
        This function takes 1 argument, an address and
        returns the number of tickets that address has purchased.
    */
    function getBuyerTicketCount(address _buyer)
    public
    view
    returns(uint numOfTickets) {
      numOfTickets = myEvent.buyers[_buyer];
      return numOfTickets;
    }
    /*
        Define a function called buyTickets().
        This function allows someone to purchase tickets for the event.
        This function takes one argument, the number of tickets to be purchased.
        This function can accept Ether.
        Be sure to check:
            - That the event isOpen x
            - That the transaction value is sufficient for the number of tickets purchased x
            - That there are enough tickets in stock x
        Then:
            - add the appropriate number of tickets to the purchasers count
            - account for the purchase in the remaining number of available tickets
            - refund any surplus value sent with the transaction
            - emit the appropriate event
    */

    function buyTickets(uint _numberOfTickets) public payable onlyWhenOpen {
      require(_numberOfTickets <= (myEvent.totalTickets - myEvent.sales), "Not enough tickets in stock");
      require(msg.value >= _numberOfTickets * TICKET_PRICE, "You have not paid enough");
      myEvent.buyers[msg.sender] += _numberOfTickets;
      myEvent.totalTickets - _numberOfTickets;
      myEvent.sales += _numberOfTickets;


      uint256 change = msg.value - _numberOfTickets * TICKET_PRICE;

      if (change > 0) {
        (bool success, ) = msg.sender.call.value(change)("");
        require(success, "Transfer failed.");
      }
      emit LogBuyTickets(msg.sender, _numberOfTickets);
    }


    /*
        Define a function called getRefund().
        This function allows someone to get a refund for tickets for the account they purchased from.
        TODO:
            - Check that the requester has purchased tickets.
            - Make sure the refunded tickets go back into the pool of avialable tickets.
            - Transfer the appropriate amount to the refund requester.
            - Emit the appropriate event.
    */

    function getRefund() public onlyWhenOpen {
      require(myEvent.buyers[msg.sender] > 0);
      uint numTickets = myEvent.buyers[msg.sender];
      myEvent.buyers[msg.sender] = 0;
      myEvent.sales -= numTickets;
      myEvent.totalTickets += numTickets;
      uint refund = numTickets * TICKET_PRICE;
      (bool success, ) = msg.sender.call.value(refund)("");
      require(success, "Transfer failed.");
      emit LogGetRefund(msg.sender, numTickets);
    }

    /*
        Define a function called endSale().
        This function will close the ticket sales.
        This function can only be called by the contract owner.
        TODO:
            - close the event
            - transfer the contract balance to the owner
            - emit the appropriate event
   */

    function endSale() public onlyWhenOpen onlyOwner {
      myEvent.isOpen = false;
      uint contractBalance = address(this).balance;
      (bool success, ) = msg.sender.call.value(contractBalance)("");
      require(success, "Transfer failed.");
      emit LogEndSale(owner, contractBalance);
    }
}
