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

pragma solidity ^0.8.22;
import "./utils/Ownable.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IPriceDAO.sol";
import "./libraries/DexhuneMath.sol";

abstract contract DexhuneExchangeBase is Ownable {
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Transfers
    function _sendToken(Token memory token, address targetAddr, uint256 amount) internal returns (bool) {
        try token.instance.transfer(targetAddr, amount) returns (bool success) {
            if (success) {
                emit TokenTransferred(amount, targetAddr, token.addr);
            }
            return success;
        } catch {
            return false;
        }
    }

    function _withdrawToken(IERC20 token, address targetAddr, uint256 amount) internal returns (bool) {
        try token.transferFrom(targetAddr, address(this), amount) returns (bool success) {
            return success;
        } catch {
            return false;
        }
    }

    function _sendAVAX(address payable to, uint256 amount) internal returns(bool) {
        (bool sent, ) = to.call{value: amount}("");

        if (sent) {
            emit AVAXTransferred(amount, to);
        }

        return sent;
    }
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Math
    function _mul(uint256 num1, uint256 num2) internal pure returns(uint256) {
        return DexhuneMath.mul(num1, num2);
        // return 0;
    }

    function _div(uint256 num1, uint256 num2) internal pure returns(uint256) {
        return DexhuneMath.div(num1, num2);
        // return 0;
    }

    function _parseNumber(string memory value) internal pure returns(uint256) {
        (uint256 num, bool success) = _tryParseNumber(value);

        if (!success) {
            revert FailedStringToNumberConversion();
        }

        return num;
    }

    function _tryParseNumber(string memory value) internal pure returns(uint256, bool) {
        uint256 xres; uint256 res;
        bytes memory buffer = bytes(value);
        uint8 b;
        
        bool hasErr;
        bool hasDec;
        uint8 dec = 0;
    
        for (uint i = 0; i < buffer.length && !hasErr; i++) {
            b = uint8(buffer[i]);
            
            if (b >= 48 && b <= 57) {
                xres = res;

                if (hasDec) {
                    dec--;
                } else {
                    res *= 10;
                }

                res += (b - 48) * 10 ** dec;

                if (xres > res) {
                    // Detect overflow
                    hasErr = true;
                }
            } else if (b == 46) {
                if (hasDec) {
                    hasErr = true;
                }

                hasDec = true;
                dec = 18;
                res *= 10 ** dec;
            }
        }

        if (!hasDec) {
            res *= 1e18;
        }

        return (res, !hasErr);
    }   
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Utils
    function _removeItem(uint256[] storage arr, uint256 index) internal {
        uint256 last = arr.length - 1;
        
        if (index != last) {
            arr[index] = arr[last];
        }

        arr.pop();
    }

    function _removeItem(Order[] storage arr, uint256 index) internal {
        uint256 last = arr.length - 1;

        if (index != last) {
            arr[index] = arr[last];
        }

        arr.pop();
    }

    function _scaleUp(uint256 amount, uint256 decimals) internal pure returns(uint256) {
        // TODO: Add this to a mapping
        return decimals == 1 ? amount : amount *  10 ** decimals;
    }

    function _scaleDown(uint256 amount, uint256 decimals) internal pure returns(uint256) {
        // TODO: Add this to a mapping
        return decimals == 1 ? amount : amount / 10 ** decimals;
    }



    function _normalize(uint256 amount, uint256 decimals) internal pure returns(uint256) {
        return decimals == 1 ? amount : amount * _computeScalar(decimals);
    }

    function _denormalize(uint256 amount, uint256 decimals) internal pure returns(uint256) {
        return decimals == 1 ? amount : amount / _computeScalar(decimals);
    }

    function _computeScalar(uint256 decimals) internal pure returns(uint256 scalar) {
        if (decimals == 18) {
            scalar = 1;
        } else {
            unchecked {
                scalar = 10 ** (18 - decimals);
            }
        }
    }
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    

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

        
        // uint256 xBalance; // Native Balance (AVAX)
        // uint256 yBalance; // Token Balance

        uint256 price;
        uint256 lastPriceCheck;

        IERC20 instance;
    }

    struct LiquidToken {
        uint256 xBalance; // Native Balance (AVAX)
        uint256 yBalance; // Token Balance
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
        address payable makerAddr;
        address tokenAddr;
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
    error OrderDoesNotExist();
    error InvalidTokenContract();
    error ParityShouldNotHavePrice();
    error InsufficientBalance(uint256 balance);
    error OnlyOwnerMustSetDefaultToken();
    error TokenNotSupported_TooManyDecimals();
    error DepositFailed();
    error NoSuitableOrderFound();
    error FailedToTakeOrder();
    error FailedToSendReward();
    error InsufficientBalanceForListing(uint256 listingPrice);
    error RejectedZeroAmount();

    
    event AssignedPriceDAO(address addr);
    event TokenListed(string indexed name, string indexed symbol, PricingScheme pricingScheme, address addr, uint256 index);
    event OrderCreated(uint256 index, bool orderType, address tokenAddr, uint256 amount, uint256 price);
    event OrderTaken(uint256 index, bool orderType, address maker, address taker, address token, uint256 amount, bool isPartial);
    event OrderReverted(uint256 index, bool orderType, address maker);
    event OrderSettled(uint256 index, bool orderType, address maker, bool isPartial);
    
    event AVAXTransferred(uint256 amount, address targetAddr);
    event TokenTransferred(uint256 amount, address targetAddr, address tokenAddr);
    
}