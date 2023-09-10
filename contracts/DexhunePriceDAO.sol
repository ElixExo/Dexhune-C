// SPDX-License-Identifier: BSD-3-Clause
/// @title Dexhune Price DAO Logic
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

import "./ERC721.sol";
import "./DexhuneBase.sol";
import "./DexhuneRoot.sol";

error NotEligibleToVote();
error AlreadyVoted();
error ProposalDoesNotExist();
error VotingDeactivated();
error ProposalIsStillActive();

contract DexhunePriceDAO is DexhuneBase, DexhuneRoot {    
    string price;
    mapping(uint256 => mapping(address => int8)) votes;
    mapping(address => uint256) tickets;

    function getPrice() public view returns(string memory) {
        return price;
    }

    function proposePrice(string memory _desc, string memory _price) external {
        uint256 id = PriceProposals.length;
        PriceProposal memory p = PriceProposal(_desc, false, 0, 0, 
            _price, block.number + PROPOSAL_BLOCKS);

        PriceProposals.push(p);
        
        emit ProposalCreated(id, _desc, msg.sender);
    }

    function voteUp(uint256 _id) external {
        if (!ensureEligible()) {
            revert NotEligibleToVote();
        }
        
        PriceProposal storage p = ensureProposal(_id);

        if (block.number > p.deadline) {
            revert VotingDeactivated();
        }

        int8 value = votes[_id][msg.sender];

        if (value == 1 || value == -1) {
            revert AlreadyVoted();
        }

        p.votesUp++;
        votes[_id][msg.sender] = 1;
        emit VotedUp(msg.sender, _id);
    }

    function voteDown(uint256 _id) external {
        if (!ensureEligible()) {
            revert NotEligibleToVote();
        }
        
        PriceProposal storage p = ensureProposal(_id);

        if (block.number > p.deadline) {
            revert VotingDeactivated();
        }
        
        int8 value = votes[_id][msg.sender];

        if (value == 1 || value == -1) {
            revert AlreadyVoted();
        }

        p.votesDown++;
        votes[_id][msg.sender] = -1;
        emit VotedDown(msg.sender, _id);
    }

    function finalizePriceProposal(uint256 _id) external {
        PriceProposal storage p = ensureProposal(_id);

        if (block.number < p.deadline) {
            revert ProposalIsStillActive();
        }

        if (p.finalized) {
            return;
        }

        if (p.votesUp > p.votesDown) {
            emit PriceUpdated(price, p.value);
            price = p.value;

            emit ProposalFinalized(_id, true);
            
        } else {
            emit ProposalFinalized(_id, false);
        }

        p.finalized = true;
    }

    function ensureEligible() private view returns(bool) {
        for (uint i = 0; i < NFTCollections.length; i++) {
            address addr = NFTCollections[i];
            IERC721 collection = IERC721(addr);

            if (collection.balanceOf(msg.sender) > 0) {
                return true;
            }
        }
        
        return false;
    }

    function ensureProposal(uint256 _id) private view returns(PriceProposal storage) {
        if (_id >= PriceProposals.length) {
            revert ProposalDoesNotExist();
        }

        return PriceProposals[_id];
    }

    /// @notice A new proposal was created
    /// @dev Notifies that a new proposal was created
    /// @param id Id of the proposal
    /// @param description Description of the proposal
    /// @param proposer Address of the proposer
    event ProposalCreated(uint256 id, string description, address proposer);

    /// @notice A proposal has been voted up
    /// @dev Notifies that a proposal has been voted up
    /// @param voter Address of the voter
    /// @param proposalId Id of the proposal
    event VotedUp(address voter, uint256 proposalId);

    /// @notice A proposal has been voted down
    /// @dev Notifies that a proposal has been voted down
    /// @param voter Address of the voter
    /// @param proposalId Id of the proposal
    event VotedDown(address voter, uint256 proposalId);

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

