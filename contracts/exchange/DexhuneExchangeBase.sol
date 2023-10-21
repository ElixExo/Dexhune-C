// SPDX-License-Identifier: BSD-3-Clause
/// @title Base objects for Dexhune Exchange
/*
*    ........................................................
*    .%%%%%...%%%%%%..%%..%%..%%..%%..%%..%%..%%..%%..%%%%%%.
*    .%%..%%..%%.......%%%%...%%..%%..%%..%%..%%%.%%..%%.....
*    .%%..%%..%%%%......%%....%%%%%%..%%..%%..%%.%%%..%%%%...
*    .%%..%%..%%.......%%%%...%%..%%..%%..%%..%%..%%..%%.....
*    .%%%%%...%%%%%%..%%..%%..%%..%%...%%%%...%%..%%..%%%%%%.
*    ........................................................
*/

pragma solidity ^0.8.21;

contract DexhuneExchangeBase {
     enum PricingScheme {
        Relative,
        Parity
    }

    struct Token {
        string name;
        string sym;
        uint8 dec;
        uint256 scalar;
        address addr;
        address parityAddr;
        
        PricingScheme scheme;

        uint256 reward;
        uint256 rewardThreshold;

        uint256 price;
        uint256 xBalance; // Balance-x (For Sells)
        uint256 yBalance; // Balance-y (For Buys)

        uint256 lastPriceCheck;
    }

    struct TokenDataModel {
        uint256 tokenNo;
        string name;
        string sym;
        address addr;
        address parityAddr;
        uint256 reward;
        uint256 rewardThreshold;
        PricingScheme scheme;
        uint256 price;

        uint256 orders;
    }

    struct Order {
        address makerAddr;
        bool orderType;

        uint256 created;
        uint256 rewardAmount;

        uint256 price;
        uint256 principal;
        uint256 pending;
    }

    error FailedStringToNumberConversion();
    error TokenAlreadyExists(address contractAddr);
    error TokenLimitReached();
    error OrderLimitReachedTryLater();
    error TokenNotListed();
    error InvalidTokenContract();
    error ParityShouldNotHavePrice();
    error InsufficientBalance(uint256 balance);
    error OnlyOwnerMustSetDefaultToken();
    error TokenNotSupported_TooManyDecimals();
    error DepositFailed();

    error UnauthorizedAccount(address account);
}