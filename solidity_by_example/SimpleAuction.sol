// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2;

contract SimpleAuction {

    /// person who receives payment at end of auction
    address payable public beneficiary;
    uint public auctionEndTime;

    // state vars of auction
    address public highestBidder;
    uint public highestBid;

    // dict mapping transactions to returns
    mapping(address => uint) pendingReturns;

    // is ended -> default value of declared bool is false
    bool ended;

    // events emitted on changes... 
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    // Triple-slash comments are called natspec comments
    // Shown on confirmation of transaction or errors

    /// The auction has already ended
    error AuctionAlreadyEnded();
    error BidNotHighEnough(uint highestBid);
    error AuctionNotYetEnded();
    error AuctionEndAlreadyCalled();

    // Builds a simple auction to execute
    constructor(
        uint biddingTime, // in seconds
        address payable beneficiaryAddress
    ) {
        beneficiary = beneficiaryAddress;
        auctionEndTime = block.timestamp + biddingTime;
    }

    // Bid transaction is implicit with bid function
    function bid() external payable {
        if (block.timestamp > auctionEndTime)
            revert AuctionAlreadyEnded();
        
        if (msg.value <= highestBid)
            revert BidNotHighEnough(highestBid);
        

        // This allows previous highest bidder to withdraw their other bid contents
        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }
        
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    // Important to keep withdraw portion separate
    function withdraw() external returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;

            if (!payable(msg.sender).send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    // Ends auction, sends to highest beneficiary
    function auctionEnd() external {
        // 1. Conditions
        if (block.timestamp < auctionEndTime)
            revert AuctionNotYetEnded();
        
        if (ended)
            revert AuctionEndAlreadyCalled();

        // 2. Effects
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        // 3. Interaction
        beneficiary.transfer(highestBid);
    }
    
}