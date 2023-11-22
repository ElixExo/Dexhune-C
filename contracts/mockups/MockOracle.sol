// SPDX-License-Identifier: BSD-3-Clause
/// @title Mock contract for ERC721 related tests
/// @dev Mock contract for Dexhune PriceDAO
/*
*    ........................................................
*    .%%%%%...%%%%%%..%%..%%..%%..%%..%%..%%..%%..%%..%%%%%%.
*    .%%..%%..%%.......%%%%...%%..%%..%%..%%..%%%.%%..%%.....
*    .%%..%%..%%%%......%%....%%%%%%..%%..%%..%%.%%%..%%%%...
*    .%%..%%..%%.......%%%%...%%..%%..%%..%%..%%..%%..%%.....
*    .%%%%%...%%%%%%..%%..%%..%%..%%...%%%%...%%..%%..%%%%%%.
*    ........................................................
*/

pragma solidity ^0.8.22;

import "../interfaces/IPriceDAO.sol";

contract MockOracle is IPriceDAO {
    string private _price;

    function getPrice() external view returns (string memory) {
        return _price;
    }

    function setPrice(string memory price) external {
        _price = price;
    }
}