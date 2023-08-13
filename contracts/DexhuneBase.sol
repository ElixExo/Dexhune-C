// SPDX-License-Identifier: BSD-3-Clause
/// @title Dexhune Events and Interfaces
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

contract DexhuneBase {
    //  30 seconds or 15 blocks, but in the testnet version we'll do 5 minutes
    uint256 internal constant MAXIMUM_VOTES_PER_PROPOSAL = 1000;
    uint256 internal constant BLOCKS_PER_SECOND = 2;
    /// @dev Total proposal duration in seconds
    uint256 internal constant PROPOSAL_DURATION = 300; // 15 blocks per 30 seconds
    uint256 internal constant PROPOSAL_BLOCKS = BLOCKS_PER_SECOND * PROPOSAL_DURATION;

     struct PriceProposal {
        uint256 id;
        string description;
        uint deadline;
        uint256 votesUp;
        uint256 votesDown;
        uint256 maxVotes;
        uint256 value;
        bool finalized;
    }

    struct Account {
        address addr;
        uint256 balance;
        address[] nfts;
    }
}