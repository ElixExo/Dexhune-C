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