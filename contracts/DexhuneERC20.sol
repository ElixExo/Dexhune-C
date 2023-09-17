// SPDX-License-Identifier: BSD-3-Clause
/// @title ERC-20 implementation for Dexhune
// Sources: 
// https://eips.ethereum.org/EIPS/eip-20
// https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
/*
*    ........................................................
*    .%%%%%...%%%%%%..%%..%%..%%..%%..%%..%%..%%..%%..%%%%%%.
*    .%%..%%..%%.......%%%%...%%..%%..%%..%%..%%%.%%..%%.....
*    .%%..%%..%%%%......%%....%%%%%%..%%..%%..%%.%%%..%%%%...
*    .%%..%%..%%.......%%%%...%%..%%..%%..%%..%%..%%..%%.....
*    .%%%%%...%%%%%%..%%..%%..%%..%%...%%%%...%%..%%..%%%%%%.
*    ........................................................
*/

pragma solidity ^0.8.18;
import "./DexhuneERC20Base.sol";

error InsufficientBalance();
error DuplicateTransferAddress();
error InvalidTransferAddress();
error NotEnoughAllowance(uint256 allowance, uint256 expectedAllowance);

contract DexhuneERC20 is DexhuneERC20Base {
    string constant NAME = "Dexhune";
    string constant SYMBOL = "DXH";
    uint8 constant DECIMALS = 0;

    
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(address => uint) private cooler;

    function name() public pure returns (string memory) {
        return NAME;
    } 

    function symbol() public pure returns (string memory) {
        return SYMBOL;
    } 

    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }

    function totalSupply() public view returns (uint256) {
        return uint128(_supply);
    }

    function balanceOf(address owner) public view returns (uint256 balance) {
        return _getFullBalance(owner);
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        _transferInternal(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        uint256 currentAllowance = allowances[from][msg.sender];

        if (value > currentAllowance) {
            revert NotEnoughAllowance(value, currentAllowance);
        }

        currentAllowance -= value;
        allowances[from][msg.sender] = currentAllowance;
        
        _transferInternal(from, to, value);
        

        return true;
    }

    function _transferInternal(address from, address to, uint256 value) private {
        uint256 balance = _getFullBalance(from);

        if (value > balance) {
            revert InsufficientBalance();
        }

        if (from == to) {
            revert DuplicateTransferAddress();
        }

        if (from == address(this)) {
            revert InvalidTransferAddress();
        }
        else if (to == address(this)) {
            revert InvalidTransferAddress();
        }

        balance -= value;

        uint256 targetBalance = _getFullBalance(to);
        targetBalance += value;

        _setBalance(from, balance);
        _setBalance(to, targetBalance);

        emit Transfer(from, to, value);
    }

    function approve(address _spender, uint256 _amount) external returns (bool) {
        allowances[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }
}