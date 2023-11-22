// SPDX-License-Identifier: BSD-3-Clause
/// @title Abstract ownable inspired by OpenZeppelin's implementation
// Sources:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
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

abstract contract Ownable {
    address public owner;

    error UnauthorizedAccount(address account);
    event TransferredOwnership(address oldOwner, address newOwner);

    function transferOwnership(address _address) public ownerOnly {
        address oldAddress = owner;
        owner = _address;
        emit TransferredOwnership(oldAddress, owner);
    }

    modifier ownerOnly() {
        _ensureOwnership();
        _;
    }

    function _ensureOwnership() private view {
        if (msg.sender != owner) {
            revert UnauthorizedAccount(msg.sender);
        }
    }
}