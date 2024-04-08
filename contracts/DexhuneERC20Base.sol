// SPDX-License-Identifier: BSD-3-Clause
/// @title Dexhune ERC20 Root Implementation
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

import "./interfaces/IERC20.sol";

abstract contract DexhuneERC20Base is IERC20 {
    address private _owner;

    address private _exchangeAddress = address(0);
    address private _daoAddress = address(0);
    uint256 private _totalMints;

    address[] private _holders;
    mapping(address => int128) private _balances;

    int128 _supply = 0;
    int16 _mintCount = 0;

    uint256 _nextMintTime = 0;
    uint256 _nextExchangeMintTime = 0;
    uint256 _nextDaoMintTime = 0;

    uint32 private constant MINT_INTERVAL = 4 days;
    uint32 private constant EXCHANGE_MINT_INTERVAL = 1 days;
    uint32 private constant DAO_MINT_INTERVAL = 1 days;

    int16 private constant MINT_LIMIT = 3650;
    
    /// @dev Mint value to add to supply divided by ten thousand. Default value is 12, indicating 0.12% [0.0012 * 10000]
    int8 private constant MINT_VALUE_PER_TEN_THOUSAND = 12;

    int32 private constant INITIAL_MINT_VALUE = 10_000_000;
    int32 private constant EXCHANGE_MINT_VALUE = 300_000;
    int32 private constant DAO_MINT_VALUE = 5760;

    address private constant DEAD_OWNER_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    

    error UnauthorizedAccount(address account);

    
    error MintedTooEarly(uint256 timeRemaining);
    error MintLimitReached();
    error InvalidBalance(address addr, int128 balance);
    error ExchangeAddressNotSet();
    error PriceDaoAddressNotSet();

    
    constructor() {
        _owner = msg.sender;

        _supply = INITIAL_MINT_VALUE;
        _addToBalance(_owner, _supply);
    }

    modifier ownerOnly() {
        _ensureOwnership();
        _;
    }

    function _ensureOwnership() private view {
        if (msg.sender != _owner) {
            revert UnauthorizedAccount(msg.sender);
        }
    }

    function setDaoAddress(address addr) external ownerOnly {
        _daoAddress = addr;

        if (_exchangeAddress != address(0)) {
            _renounceContract();
        }
    }

    function setExchangeAddress(address addr) external ownerOnly {
        _exchangeAddress = addr;

        if (_daoAddress != address(0)) {
            _renounceContract();
        }
    }

    function getOwner() external view returns(address) {
        return _owner;
    }

    function mintingStartsAfter() external view returns (uint256) {
        uint256 timestamp = block.timestamp;

        if (_nextMintTime < timestamp) {
            return 0;
        }

        return _nextMintTime - timestamp;
    }

    function exchangeMintingStartsAfter() external view returns (uint256) {
        uint256 timestamp = block.timestamp;

        if (_nextExchangeMintTime < timestamp) {
            return 0;
        }

        return _nextExchangeMintTime - timestamp;
    }

    function daoMintingStartsAfter() external view returns (uint256) {
        uint256 timestamp = block.timestamp;

        if (_nextDaoMintTime < timestamp) {
            return 0;
        }

        return _nextDaoMintTime - timestamp;
    }

    function mint() external {
        if (_mintCount >= MINT_LIMIT) {
            revert MintLimitReached();
        }

        if (block.timestamp < _nextMintTime) {
            revert MintedTooEarly(block.timestamp - _nextMintTime);
        }

        _mintCount++;
        _nextMintTime = block.timestamp + MINT_INTERVAL;

        int128 supply = _supply;
        int128 delegated = (supply * MINT_VALUE_PER_TEN_THOUSAND) / 10000;
        
        int128 distributed = _distribute(delegated);
        int128 rem = delegated - distributed;

        if (rem > 0) {
            if (_exchangeAddress != address(0)) {
                _addToBalance(_exchangeAddress, rem);
            } else if (_daoAddress != address(0)) {
                _addToBalance(_daoAddress, rem);
            } else {
                _addToBalance(_owner, rem);
            }
        }

        _supply += delegated;
    }


    function mintToExchange() external {
        if (_nextExchangeMintTime > block.timestamp) {
            revert MintedTooEarly(_nextExchangeMintTime - block.timestamp);
        }

        if (_exchangeAddress == address(0)) {
            revert ExchangeAddressNotSet();
        }

        _nextExchangeMintTime = block.timestamp + EXCHANGE_MINT_INTERVAL;
        _addToBalance(_exchangeAddress, EXCHANGE_MINT_VALUE);
    }

    function mintToDao() external {
        if (block.timestamp < _nextDaoMintTime) {
            revert MintedTooEarly(block.timestamp - _nextDaoMintTime);
        }

        if (_daoAddress == address(0)) {
            revert PriceDaoAddressNotSet();
        }

        _nextDaoMintTime = block.timestamp + DAO_MINT_INTERVAL;
        _addToBalance(_daoAddress, DAO_MINT_VALUE);
    }

    function _renounceContract() private {
        _owner = DEAD_OWNER_ADDRESS;
    }

    function _getBalance(address addr) internal view returns(int128) {
        int128 balance = _balances[addr];

        if (balance < 0) {
            balance = 0;
        }

        return balance;
    }

    function _getFullBalance(address addr) internal view returns(uint256) {
        return uint128(_getBalance(addr));
    }

    function _setBalance(address addr, int128 balance) private {
        if (balance < 0) {
            revert InvalidBalance(addr, balance);
        }

        if (balance == 0) {
            balance = -1;
        }

        int128 oldBalance = _balances[addr];

        // User does not have a balance, no further changes required
        if (oldBalance == 0 && balance == -1) {
            return;
        }

        // Balance is zero, user does not exist
        if (oldBalance == 0) {
            _holders.push(addr);
        }

        _balances[addr] = balance;
    }

    function _setBalance(address addr, uint256 balance) internal {
        _setBalance(addr, int128(uint128(balance)));
    }

    function _addToBalance(address addr, int128 value) private {
        int128 balance = _balances[addr];

        // Balance is zero, user does not exist
        if (balance == 0) {
            _holders.push(addr);
        }

        balance += value;
        _balances[addr] = balance;

        emit Transfer(address(this), addr, uint128(value));
    }

    function _distribute(int128 funds) private returns (int128) {
        address holder;
        int128 balance;

        int128 cut;
        int128 distributed;

        for (uint i = 0; i < _holders.length; i++) {
            holder = _holders[i];
            balance = _balances[holder];
        
            cut = (balance * funds) / _supply;
            
            balance += cut;
            distributed += cut;

            _balances[holder] = balance;

            if (cut > 0) {
                emit Transfer(address(this), holder, uint128(cut));
            }
        }

        return distributed;
    }
}