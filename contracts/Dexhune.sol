// SPDX-License-Identifier: BSD-3-Clause
/// @title Dexhune Smart Contract
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

import "./DexhuneRoot.sol";
import "./DexhuneAccounts.sol";
import "./DexhuneDAO.sol";

contract Dexhune is DexhuneRoot, DexhuneDAO, DexhuneAccounts {
    uint256 public totalSupply;
    

    function transfer(address recipient, uint256 amount) external returns(bool) {
        accounts[msg.sender]
    }


}
