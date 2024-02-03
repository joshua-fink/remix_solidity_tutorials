// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/// @title Voting with delegation
contract Ballot {
    
    // This the unit of organization for a voter
    struct Voter {
        uint weight; // weight accumulated by delegation
        bool voted; // true if already voted
        address delegate; // person delegated to
        uint vote; // index of the voted proposal
    }

    // Proposal data
    struct Proposal {
        bytes32 name; // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    // Voting contract owner
    address public chairperson;

    mapping(address => Voter) public voters;

    Proposal[] public proposals;

    // constructor to build contract with input for proposals to vote on
    constructor(bytes32[] memory proposalNames) {
        chairperson = msg.sender;
        voters[chairperson].weight = 10;
        
        // creates proposal object for each proposal name
        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({
                name: proposalNames[i], // name of proposal
                voteCount: 0 // initialized to zero obviously
            }));
        }
    }

    modifier onlyChairperson() {
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        _;
    }

    modifier voterHasNotVoted(address voter) {
        require(
            !voters[voter].voted,
            "The voter already voted."
        );
        _;
    }

    modifier voterHasPower(address voter) {
        require(
            voters[voter].weight != 0,
            "You have no right to vote"
        );
        _;
    }

    function giveRightToVote(address voter, uint weight) external 
        onlyChairperson() voterHasNotVoted(voter) {
        // chairperson manually adds rights to voters
        require(voters[voter].weight == 0);
        voters[voter].weight = weight;
    }

    function delegate(address to) external 
        voterHasNotVoted(msg.sender) voterHasPower(msg.sender) voterHasPower(to) {
        
        Voter storage sender = voters[msg.sender];
        require(to != msg.sender, "Self-delgation is not allowed");
        
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // this line is important, prevents this from going forward forever
            // kinda union-find esque haha
            require(to != msg.sender, "Found loop in delegation");
        }

        Voter storage delegate_ = voters[to];

        sender.voted = true;
        sender.delegate = to;

        // Amplify delegate's voting power, action taken depends on if delegate voted or not
        if (delegate_.voted) {
            proposals[delegate_.vote].voteCount += sender.weight;
        }
        else {
            delegate_.weight += sender.weight;
        }
    }

    function vote(uint proposal) external 
        voterHasNotVoted(msg.sender) voterHasPower(msg.sender) {
        
        Voter storage sender = voters[msg.sender];
        sender.voted = true;
        sender.vote = proposal;

        proposals[proposal].voteCount += sender.weight;
    }

    function winningProposal() public view returns (uint winningProposal_) {
        uint winningVoteCount = 0;
        for (uint p=0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    function winnerName() external view returns (bytes32 winnerName_) {
        winnerName_ = proposals[winningProposal()].name;
    }

}