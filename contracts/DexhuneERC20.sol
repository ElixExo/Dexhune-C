// SPDX-License-Identifier: BSD-3-Clause
/// @title ERC-20 implementation for Dexhune
// Sources: 
// https://eips.ethereum.org/EIPS/eip-20
// https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM
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


contract DexhuneERC20 {
    string constant NAME = "Dexhune";
    string constant SYMBOL = "DXH";
    uint8 constant DECIMALS = 18;

    uint256 supply = type(uint256).max;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(address => uint) private transferTimer;

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
        return supply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        _transferInternal(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _sender, address _to, uint256 _value) external returns (bool) {
        require(false, "This operatation is not supported");

        _transferInternal(_sender, _to, _value);
        return true;
    }

    function _transferInternal(address _sender, address _to, uint256 _value) private {
        uint256 balance = balances[_sender];
        require(balance - _value >= 0, "Insufficient balance");

        balances[_sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
    }

    function approve(address _spender, uint256 _amount) external returns (bool) {
        allowances[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        
        return true;
    }






    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}