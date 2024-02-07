// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2;

contract BlindAuction {

    // this represents an individual bid
    struct Bid {
        bytes32 blindedBid; // obfusticated bid
        uint deposit;
    }

    // who ultimately receives bid outcome
    address payable public beneficiary;
    
    // time auction ends
    uint public biddingEnd;

    // time auction outcome is revealed
    uint public revealEnd;

    // blind action active or not
    bool public ended;

    // record of all bids -> maps address to bid list
    mapping(address => Bid[]) public bids;

    // state of highest bidder
    address public highestBidder;
    uint public highestBid;

    // how much to return
    mapping(address => uint) pendingReturns;

    // auction ended event to emit
    event AuctionEnded(address winner, uint highestBid);

    /// The function has been called too early.
    /// Try again at `time`
    error TooEarly(uint time);
    /// The function has been called too late.
    /// It cannot be called after `time`.
    error TooLate(uint time);
    /// Function auctionEnd already called.
    error AuctionEndAlreadyCalled();
    
    // Modifiers -> validate function inputs
    modifier onlyBefore(uint time) {
        if (block.timestamp >= time) revert TooLate(time);
        _;
    }

    modifier onlyAfter(uint time) {
        if (block.timestamp <= time) revert TooEarly(time);
        _;
    }

    constructor(
        uint biddingTime,
        uint revealTime,
        address payable beneficiaryAddress
    ) {
        beneficiary = beneficiaryAddress;
        biddingEnd = block.timestamp + biddingTime;
        revealEnd = biddingEnd + revealTime;
    }

    function bid(bytes32 blindedBid) 
        external
        payable 
        onlyBefore(biddingEnd)
    {
        bids[msg.sender].push(Bid({
            blindedBid: blindedBid,
            deposit: msg.value
        }));
    }

    function reveal(
        uint[] calldata values,
        bool[] calldata fakes,
        bytes32[] calldata secrets
    )
        external
        onlyAfter(biddingEnd)
        onlyBefore(revealEnd)
    {
        // check if inputs match the bid list length
        uint length = bids[msg.sender].length;
        require(values.length == length);
        require(fakes.length == length);
        require(secrets.length == length);

        // initialize refund variable
        uint refund;
        for (uint i = 0; i < length; i++) {
            Bid storage bidToCheck = bids[msg.sender][i];
            (uint value, bool fake, bytes32 secret) = 
                (values[i], fakes[i], secrets[i]);
            

            if (bidToCheck.blindedBid != keccak256(abi.encodePacked(value, fake, secret))) {
                continue;
            }
            refund += bidToCheck.deposit;
            
            if (!fake && bidToCheck.deposit >= value) {
                if (placeBid(msg.sender, value))
                    refund -= value;
            }

            bidToCheck.blindedBid = bytes32(0);
        }

        payable(msg.sender).transfer(refund);
    }

    function withdraw() external {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            payable(msg.sender).transfer(amount);
        }
    }

    function auctionEnd()
        external
        onlyAfter(revealEnd)
    {
        if (ended) revert AuctionEndAlreadyCalled();
        emit AuctionEnded(highestBidder, highestBid);
        ended = true;
        beneficiary.transfer(highestBid);
    }

    function placeBid(address bidder, uint value) internal
        returns (bool success)
    {
        if (value <= highestBid) {
            return false;
        }

        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBid = value;
        highestBidder = bidder;
        return true;
    }
}