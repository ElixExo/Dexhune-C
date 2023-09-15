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

import "./DexhuneBase.sol";
import "./DexhuneRoot.sol";

error NotEligibleToVote();
error AlreadyVoted();
error ProposalDoesNotExist();
error VotingDeactivated();
error ProposalIsStillActive();
error ProposalHasExpired();

interface IERC721Proxy {
    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract DexhunePriceDAO is DexhuneBase, DexhuneRoot {    
    string price;
    uint256 votingDeadline;
    uint256 deadline;

    mapping(uint256 => mapping(address => int8)) votes;
    mapping(address => uint256) tickets;

    /// @dev Total proposal duration in seconds
    uint256 internal constant PROPOSAL_DURATION = 600; // 15 blocks per 30 seconds\

    /// @dev Total proposal voting duration in seconds
    uint256 internal constant PROPOSAL_VOTING_DURATION = 300;
    uint256 internal constant PROPOSAL_BLOCKS = BLOCKS_PER_SECOND * PROPOSAL_DURATION;
    uint256 internal constant PROPOSAL_VOTING_BLOCKS = BLOCKS_PER_SECOND * PROPOSAL_VOTING_DURATION;

    uint256 internal constant VERIFICATION_TICKET_DURATION = 3600; // 1 hour
    uint256 internal constant VERIFICATION_TICKET_BLOCKS = BLOCKS_PER_SECOND * VERIFICATION_TICKET_DURATION;

    function getPrice() public view returns(string memory) {
        return price;
    }

    function latestProposal() public view  returns (string memory description, string memory value, uint256 votesUp, uint256 votesDown) {
        PriceProposal memory p = PriceProposals[PriceProposals.length - 1];
        return (p.description, p.value, p.votesUp, p.votesDown);
    }

    function votingEndsAt() public view returns (uint256) {
        return votingDeadline;
    }

    function proposalExpiresAt() public view returns (uint256) {
        return deadline;
    }

    function proposePrice(string memory _desc, string memory _price) external {
        uint256 id = PriceProposals.length;
        if (id > 0) {
            if (!PriceProposals[id - 1].finalized) {
                if (deadline > block.number) {
                    revert ProposalIsStillActive();
                }
            }
        }
        
        PriceProposal memory p = PriceProposal(_desc, _price, 
            0, 0, false);

        votingDeadline = block.number + PROPOSAL_VOTING_BLOCKS; 
        deadline = block.number + PROPOSAL_BLOCKS;

        PriceProposals.push(p);
        
        emit ProposalCreated(id, _desc, msg.sender);
    }

    function voteUp() external {
        if (!ensureEligible()) {
            revert NotEligibleToVote();
        }

        uint256 _id = PriceProposals.length - 1;
        PriceProposal storage p = ensureProposal(_id);

        if (block.number >= votingDeadline) {
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

    function voteDown() external {
        if (!ensureEligible()) {
            revert NotEligibleToVote();
        }
        
        uint256 _id = PriceProposals.length - 1;
        PriceProposal storage p = ensureProposal(_id);

        if (block.number >= votingDeadline) {
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

    function finalizeProposal() external {
        uint256 _id = PriceProposals.length - 1;
        PriceProposal storage p = ensureProposal(_id);
        
        if (votingDeadline > block.number) {
            revert ProposalIsStillActive();
        }

        if (block.number >= deadline) {
            revert ProposalHasExpired();
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

    function ensureEligible() private returns(bool) {
        if (block.number < tickets[msg.sender]) {
            return true;
        }
        
        for (uint i = 0; i < NFTCollections.length; i++) {
            address addr = NFTCollections[i];
            IERC721Proxy collection = IERC721Proxy(addr);

            if (collection.balanceOf(msg.sender) > 0) {
                tickets[msg.sender] = block.number + VERIFICATION_TICKET_BLOCKS;
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

