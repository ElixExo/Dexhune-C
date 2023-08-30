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
import "./DexhunePriceDAO.sol";

contract Dexhune is DexhuneRoot, DexhunePriceDAO, DexhuneAccounts {
}
