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
        uint256 deadline;
        uint256 votesUp;
        uint256 votesDown;
        string value;
        mapping(address => int8) votes;
        bool finalized;
        bool exists;
    }
}