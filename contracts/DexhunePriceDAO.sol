// SPDX-License-Identifier: BSD-3-Clause
/// @title Dexhune Oracle/Price DAO Logic
/*
*    ........................................................
*    .%%%%%...%%%%%%..%%..%%..%%..%%..%%..%%..%%..%%..%%%%%%.
*    .%%..%%..%%.......%%%%...%%..%%..%%..%%..%%%.%%..%%.....
*    .%%..%%..%%%%......%%....%%%%%%..%%..%%..%%.%%%..%%%%...
*    .%%..%%..%%.......%%%%...%%..%%..%%..%%..%%..%%..%%.....
*    .%%%%%...%%%%%%..%%..%%..%%..%%...%%%%...%%..%%..%%%%%%.
*    ........................................................
*/

pragma solidity ^0.8.21;

import "./interfaces/IERC20.sol";
import "./DexhunePriceDAOBase.sol";

contract DexhunePriceDAO is DexhunePriceDAOBase {    
    string private _price;
    uint256 private _deadline;
    uint256 private _votingDeadline;
    PriceProposal private _proposal;

    address[] private _voters;
    mapping(address => int16) private _votes;
    
    uint256 internal constant PROPOSAL_DURATION = 10 minutes;
    uint256 internal constant PROPOSAL_VOTING_DURATION = 5 minutes;

    uint256 private constant MAX_REWARD = 20_000;
    uint256 private constant REWARD_MULTIPLIER = 20;

    constructor() {
        owner = msg.sender;
        _proposal = PriceProposal(owner, "NULL", "NULL", true);
    }

    function getPrice() public view returns(string memory) {
        return _price;
    }

    function latestProposal() public view returns (PriceProposal memory) {
        return _proposal;
    }

    function votingEndsAt() public view returns (uint256) {
        return _votingDeadline;
    }

    function proposalExpiresAt() public view returns (uint256) {
        return _deadline;
    }

    function proposePrice(string memory price, string memory description) external {        
        if (_getHolderBalance() <= 0) {
            revert NotEligible();
        }

        if (_proposal.finalized) {
            if (_deadline > block.timestamp) {
                revert ProposalIsStillActive();
            }
        }

        _deadline = block.timestamp + PROPOSAL_DURATION;
        _votingDeadline = block.timestamp + PROPOSAL_VOTING_DURATION;
        
        _proposal = PriceProposal(msg.sender, price, description, false);
        
        emit ProposalCreated(price, description, msg.sender);
    }

    function voteUp() external {
        uint16 balance = _checkVotes();
        address voter = msg.sender;

        _voters.push(voter);
        _votes[voter] = int16(balance);
        emit VotedUp(voter, balance);
    }

    function voteDown() external {
        uint16 balance = _checkVotes();
        address voter = msg.sender;
        
        _voters.push(voter);
        _votes[voter] = -int16(balance);
        emit VotedDown(voter, balance);
    }

    function finalizeProposal() external {
        if (_votingDeadline > block.timestamp) {
            revert ProposalIsStillActive();
        } else if (block.timestamp >= _deadline) {
            revert ProposalHasExpired();
        } else if (_proposal.finalized) {
            revert ProposalAlreadyFinalized();
        }

        uint16 up;
        uint16 down;
        
        int16 value;
        uint16 balance;

        address voterAddr;

        for (uint256 i = _voters.length - 1; i >= 0; i--) {
            voterAddr = _voters[i];
            value = _votes[voterAddr];
            
            unchecked {
                balance = uint16(_getHolderBalance(voterAddr));
            }

            if (_abs(value) != balance) {
                continue;
            }

            if (value > 0) {
                up += uint16(value);
            } else if (value < 0) {
                down += uint16(-value);
            }
        }

        _proposal.finalized = true;

        if (up > down) {
            _rewardProposer(up + down);
            _price = _proposal.value;

            emit ProposalPassed(up, down, _price);
            
        } else {
            emit ProposalDenied(up, down);
        }
    }

    function _checkVotes() private view returns (uint16) {
        if (block.timestamp >= _votingDeadline) {
            revert NoActiveProposal();
        }

        int16 value = _votes[msg.sender];

        if (value != 0) {
            revert AlreadyVoted();
        }

        // Overflow if balance is greater than 1k (Only 1k Peng NFTs should exist)
        uint16 balance = uint16(_getHolderBalance());
        
        if (balance <= 0) {
            revert NotEligible();
        }

        return balance;
    }

    function _rewardProposer(uint16 total) private {
        address addr = _proposal.proposerAddr;
        uint256 reward = total * REWARD_MULTIPLIER;

        if (reward > MAX_REWARD) {
            reward = MAX_REWARD;
        }

        try _token.transfer(addr, reward) {
            emit RewardedProposer(addr, reward);
        } catch {}
    }
}

