// SPDX-License-Identifier: BSD-3-Clause
/// @title Mock contract for ERC20 related tests
/// @dev Allows user balance to be set and retrieved
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
import "../interfaces/IERC20.sol";

contract MockERC20 is IERC20 {
    mapping(address => uint256) balances;
    uint8 private _decimals = 18;

    function setBalance(address addr, uint256 balance) external {
        balances[addr] = balance;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function name() external pure override returns (string memory) {
        return "MockERC20";
    }

    function symbol() external pure override returns (string memory) {
        return "MCKERC20";
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function setDecimals(uint8 dec) external {
        _decimals = dec;
    }

    function totalSupply() external pure override returns (uint256) {
        return type(uint256).max;
    }

    function transfer(
        address to,
        uint256 value
    ) external override returns (bool) {
        require(balances[msg.sender] >= value);

        balances[msg.sender] -= value;
        balances[to] += value;

        return true;
    }

    function allowance(
        address owner,
        address spender
    ) external pure override returns (uint256) {
        return 0;
    }

    function approve(
        address spender,
        uint256 value
    ) external pure override returns (bool) {
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        require(balances[from] >= value);

        balances[from] -= value;
        balances[to] += value;

        return true;
    }
}