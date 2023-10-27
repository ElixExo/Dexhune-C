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
import "./interfaces/IERC20.sol";

abstract contract DexhuneExchangeBase {
    address public owner;

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Ownership
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
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Transfers
    function _sendToken(IERC20 token, address targetAddr, uint256 amount) internal returns (bool) {
        try token.transfer(targetAddr, amount) returns (bool success) {
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

        return sent;
    }
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////


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
        IERC20 instance;
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
    error InvalidTokenContract();
    error ParityShouldNotHavePrice();
    error InsufficientBalance(uint256 balance);
    error OnlyOwnerMustSetDefaultToken();
    error TokenNotSupported_TooManyDecimals();
    error DepositFailed();
    error NoSuitableOrderFound();
    error FailedToTakeOrder();

    error InsufficientBalanceForListing(uint256 listingPrice);

    error UnauthorizedAccount(address account);


    event TransferredOwnership(address oldOwner, address newOwner);
}