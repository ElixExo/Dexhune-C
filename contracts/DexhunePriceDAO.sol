// SPDX-License-Identifier: BSD-3-Clause
/// @title Dexhune DAO Logic
/*
*    ........................................................
*    .%%%%%...%%%%%%..%%..%%..%%..%%..%%..%%..%%..%%..%%%%%%.
*    .%%..%%..%%.......%%%%...%%..%%..%%..%%..%%%.%%..%%.....
*    .%%..%%..%%%%......%%....%%%%%%..%%..%%..%%.%%%..%%%%...
*    .%%..%%..%%.......%%%%...%%..%%..%%..%%..%%..%%..%%.....
*    .%%%%%...%%%%%%..%%..%%..%%..%%...%%%%...%%..%%..%%%%%%.
*    ........................................................
*/

pragma solidity >=0.4.22 <0.9.0;

import "./DexhuneBase.sol";
import "./DexhuneRoot.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


contract DexhunePriceDAO is DexhuneBase, DexhuneRoot {    
    string price;
    uint256 proposalCount = 0;
    mapping(uint256 => PriceProposal) public PriceProposals;

    function getPrice() public view returns(string memory) {
        return price;
    }

    function proposePrice(string memory _desc, string memory _price) public {
        PriceProposal storage p = PriceProposals[proposalCount];
        p.id = proposalCount;
        p.description = _desc;
        p.value = _price;
        p.exists = true;
        p.deadline = block.number + PROPOSAL_BLOCKS;
        

        emit ProposalCreated(proposalCount, _desc, msg.sender);
        proposalCount++;
    }


    function castPriceVote(uint256 _id, bool _vote) public {
        require(ensureEligible(), "You are not eligible to vote.");
        
        PriceProposal storage p = PriceProposals[_id];
        require(p.exists, "The requested proposal does not exist");
        require(
            block.number < p.deadline,
            "Voting has been deactivated for this proposal"
        );
        
        int8 value = p.votes[msg.sender];
        bool hasVoted = value == 1 || value == -1;

        require(!hasVoted, "You are not allowed to vote more than once");        

        if (_vote) {
            p.votesUp++;
            p.votes[msg.sender] = 1;
        } else {
            p.votesDown++;
            p.votes[msg.sender] = -1;
        }

        emit VoteCast(msg.sender, _id, _vote);
    }

    function finalizePriceProposal(uint256 _id) public {
        PriceProposal storage p = PriceProposals[_id];
        require(p.exists, "The requested proposal does not exist");
        require(
            block.number > p.deadline,
            "The requested proposal is still active"
        );

        if (p.finalized) {
            return;
        }

        if (p.votesUp > p.votesDown) {
            string memory old = price;
            price = p.value;

            emit ProposalFinalized(_id, true);
            emit PriceUpdated(old, price);
        } else {
            emit ProposalFinalized(_id, false);
        }

        p.finalized = true;
    }

    function ensureEligible() private view returns(bool) {
        for (uint i = 0; i < nftCollections.length; i++) {
            address addr = nftCollections[i];
            IERC721 collection = IERC721(addr);

            if (collection.balanceOf(msg.sender) > 0) {
                return true;
            }
        }
        
        return false;
    }

    /// @notice A new proposal was created
    /// @dev Notifies that a new proposal was created
    /// @param id Id of the proposal
    /// @param description Description of the proposal
    /// @param proposer Address of the proposer
    event ProposalCreated(uint256 id, string description, address proposer);


    /// @notice A vote has been cast on a proposal
    /// @dev Notifies that a vote has been casted
    /// @param voter Address of the voter
    /// @param proposalId Id of the proposal
    /// @param votedFor Indicates whether the voter voted for or against
    event VoteCast(address voter, uint256 proposalId, bool votedFor);

    /// @notice Voting result of the Proposal
    /// @dev Notifies that a proposal has been finalized
    /// @param id Id of the proposal
    /// @param passed Result of the voting on proposal, passed defines that the proposal is accepted by the voters
    event ProposalFinalized(uint256 id, bool passed);

    /// @notice The price has been updated
    /// @dev Notifies that the price has been updated
    /// @param oldPrice The previous price that was replaced
    /// @param newPrice The new price replacing the previous price
    event PriceUpdated(string oldPrice, string newPrice);
}

