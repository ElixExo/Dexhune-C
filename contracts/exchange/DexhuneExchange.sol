// SPDX-License-Identifier: BSD-3-Clause
/// @title Dexhune Exchange implementation
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

import "./../interfaces/IERC20.sol";
import "./../interfaces/IPriceDAO.sol";
import "./../libraries/ERC165Checker.sol";
import "./DexhuneExchangeBase.sol";
import "./../utils/ERC20Normalizer.sol";
import { UD60x18, div, convert, wrap, unwrap } from "@prb/math/src/UD60x18.sol";

/** 
 * @dev Derived interface as specified Dexhune documents 
*/
interface IDexhuneExchange {
    function makeOrder(address tokenAddr, string memory amount, bool orderType) external;
    function takeOrder(address tokenAddr, string memory amount) external view;
    function settleOrders(address tokenAddr, bool orderType) external;
    function deposit(address fromAddress, address tokenAddr, bool balanceType, string memory amount) external;
    function clearOrders() external;
    function queryOrder(uint8 queryType, string memory queryDetails) external;
    function queryListing(uint8 queryType, string memory queryDetails) external;
    function queryPrice() external returns(uint256);
    function getBalance() external view returns(uint256);
    function claimUnallocated(address tokenAddr, bool isAVAX) external;
    function queryBalance(address contractAddr, bool balanceType) external view;

    function listToken(address tokenContract, uint256 rewardAmount, uint256 rewardThreshold, address parityAddr, string memory price) external;
}

// 

contract DexhuneExchange is DexhuneExchangeBase, ERC20Normalizer {
    Token[] private _tokens;
    Order[] private _orders;

    mapping(address => uint256) private _tokenMap;
    mapping(address => uint256[]) private _ordersByToken;
    mapping(address => uint256[]) private _ordersByUser;


    address private _owner;
    address private _dxhAddr;
    address private _oracleAddr;
    
    uint256 _price;
    uint256 _lastPriceCheck;

    uint256 private constant NATIVE_TOKEN_DECIMALS = 18;
    uint256 private constant MAX_ORDER_COUNT = 100_000;
    uint256 private constant MAX_TOKEN_COUNT = 1_000_000;
    uint256 private constant ORDER_LIFESPAN = 40 seconds;
    uint256 private constant PRICE_CHECK_INTERVAL = 4 minutes;
    
    constructor() {
        _owner = msg.sender;
        // _erc20InterfaceId = type(IERC20).interfaceId;
    }

    function viewToken(address tokenAddr) external view returns (TokenDataModel memory) {
        uint256 index = _tokenMap[tokenAddr];

        if (index == 0) {
            revert TokenNotListed();
        }

        return _displayToken(index);
    }

    function viewToken(uint256 tokenNo) external view returns (TokenDataModel memory) {
        if (tokenNo >= _tokens.length) {
            revert TokenNotListed();
        }

        return _displayToken(tokenNo);
    }

    function listToken(address contractAddr, PricingScheme scheme, uint256 reward, uint256 rewardThreshold, address parityAddr, string memory price) external {
        if (_tokens.length == 0) {
            if (msg.sender != _owner) {
                revert OnlyOwnerMustSetDefaultToken();
            }
        }

        uint256 index = _tokenMap[contractAddr];

        if (index != 0 && _tokens.length > 0) {
            revert TokenAlreadyExists(contractAddr);
        }

        if (_tokens.length >= MAX_TOKEN_COUNT) {
            revert TokenLimitReached();
        }
        
        IERC20 tokenInstance = IERC20(contractAddr);
        uint8 decimals;
        string memory name;
        string memory sym;

        try tokenInstance.balanceOf(_owner) {
            try tokenInstance.decimals() returns (uint8 _dec) {
                decimals = _dec;
            } catch {
                decimals = 18;
            }

            if (decimals > 18) {
                revert TokenNotSupported_TooManyDecimals();
            }

            try tokenInstance.name() returns (string memory _name) {
                name = _name;
            } catch {}

            try tokenInstance.symbol() returns (string memory _sym) {
                sym = _sym;
            } catch {}
        } catch {
            revert InvalidTokenContract();
        }

        uint256 scalar = _computeScalar(decimals);



        uint256 nPrice = _parseNumber(price);

        if (parityAddr != address(0) && nPrice > 0) {
            revert ParityShouldNotHavePrice();
        }

        Token memory token = Token(
            name, sym, decimals, scalar, 
            contractAddr, parityAddr,
            scheme, reward, rewardThreshold,
            nPrice, 0, 0, 0
        );

        _tokens.push(token);
        _tokenMap[contractAddr] = index + 1;
    }
    
    function createBuyOrder(address tokenAddr) external payable {
        uint256 amount = msg.value;
        Token memory token = _fetchToken(tokenAddr);

        _createOrder(token, true, amount);
    }

    function createSellOrder(address tokenAddr, uint256 amount) external {
        Token memory token = _fetchToken(tokenAddr);

        _createOrder(token, false, amount);
    }

    function _createOrder(Token memory token, bool orderType, uint256 amount) private {
        uint256 price;

        if (token.scheme == PricingScheme.Relative) {
            _ensurePrice();
            price = _div(_price, token.price);
        } else if (token.scheme == PricingScheme.Parity) {
            bool canUpdate = block.timestamp - token.lastPriceCheck >= PRICE_CHECK_INTERVAL;

            if (canUpdate) {
                IERC20 tokenInst = IERC20(token.addr);
                IERC20 dxhInst = IERC20(_dxhAddr);

                uint256 tBalance = tokenInst.balanceOf(token.parityAddr);
                uint256 dxhBalance = dxhInst.balanceOf(token.parityAddr);

                token.price = price = _div(dxhBalance, tBalance);
                token.lastPriceCheck = block.timestamp;
            }
        }

        uint256 pending;

        uint256 nPrice = _normalize(price, token.dec);
        uint256 nAmount = _normalize(amount, NATIVE_TOKEN_DECIMALS);
        pending = _denormalize(nPrice * nAmount, token.dec);


        uint reward;

        if (price >= token.rewardThreshold) {
            reward = token.reward;
        }

        Order memory order = Order(msg.sender, orderType, block.timestamp, reward, price, amount, pending);
        _orders.push(order);

        uint256[] storage uorders = _ordersByUser[msg.sender];
        uint256[] storage torders = _ordersByToken[token.addr];

        uint256 index = _orders.length - 1;
        uorders.push(index);
        torders.push(index);
    }

    function deposit(address tokenAddr, address fromAddress, bool balanceType) external payable {
        Token memory token = _fetchToken(tokenAddr);
        uint256 amount = msg.value;

        if (!_withdraw(token.addr, fromAddress, amount)) {
            revert DepositFailed();
        }

        if (balanceType) {
            token.xBalance += amount;
        } else {
            token.yBalance += amount;
        }
    }

    function settleOrders(address tokenAddr, bool orderType) external {
        Token memory token = _fetchToken(tokenAddr);

        uint256[] storage norders = _ordersByToken[token.addr];
        Order memory order;

        bool settled;
        uint256 balance = orderType ? token.yBalance : token.xBalance;
        
        for (uint i = norders.length - 1; balance > 0 && i >= 0; i--) {
            uint256 n = norders[i];
            order = _orders[n];

            if (order.orderType != orderType) {
                continue;
            }

            if (orderType) {
                (settled, balance) = _settleBuyOrder(token, order, balance);
            } else {
                (settled, balance) = _settleSellOrder(token, order, balance);
            }

            if (!settled) {
                continue;
            }

             if (i != norders.length - 1) {
                norders[i] = norders[norders.length - 1];
            }

            if (n != _orders.length - 1) {
                _orders[n] = _orders[_orders.length - 1];
            }

            norders.pop();
            _orders.pop();
        }
    }

    function _settleBuyOrder(Token memory token, Order memory order, uint256 balance) private returns (bool settled, uint256 remBalance) {
        uint256 amount;
        bool isPartial = balance < order.principal;
        
        if (isPartial) {
            amount = balance;
        } else {
            amount = order.principal;
        }

        IERC20 inst = IERC20(token.addr);

        try inst.transfer(order.makerAddr, amount) {
            balance -= amount;
        } catch {
            return (false, balance);
        }

        return (!isPartial, balance);
    }

    function _settleSellOrder(Token memory token, Order memory order, uint256 balance) private returns (bool settled, uint256 remBalance) {
        uint256 amount;
        bool isPartial = balance < order.principal;

        if (isPartial) {
            amount = balance;
        } else {
            amount = order.principal;
        }

        if (_sendAmount(order.makerAddr, amount)) {
            balance -= amount;
            return (true, balance);
        }
        
        return (false, balance);
    }

    function _withdraw(address tokenAddr, address targetAddr, uint256 amount) private returns (bool) {
        IERC20 token = IERC20(tokenAddr);
        
        try token.transferFrom(targetAddr, address(this), amount) returns (bool success) {
            return success;
        } catch {
            return false;
        }
    }

    function _sendAmount(address to, uint256 amount) private returns(bool) {
        (bool sent, ) = to.call{value: amount}("");

        return sent;
    }

    // function _settleBuyOrders(Token token) private {
    //     uint256[] memory norders = _ordersByToken[token.addr];
    //     Order memory order;

    //     uint256 amount;
    //     bool settled;
    //     uint256 balance = token.yBalance;

    //     for (int i = norders.length - 1; balance > 0 && i >= 0; i--) {
    //         uint256 n = norders[i];
            
    //         order = _orders[n];
            
    //         if (!order.orderType) {
    //             continue;
    //         }

    //         settled = order.principal > balance;
    //         if (settled) {
    //             amount = balance;
    //         } else {
    //             amount = order.principal;
    //         }

    //         IERC20 inst = IERC20(token.addr);

    //         try inst.transfer(order.makerAddr, amount) {
    //             balance -= amount;
    //             // order.pending = 
    //         } catch {
    //             continue;
    //         }

    //         if (!settled) {
    //             continue;
    //         }

    //         if (i != norders.length - 1) {
    //             norders[i] = norders[norders.length - 1];
    //         }

    //         if (n != _orders.length - 1) {
    //             _orders[n] = _orders[_orders.length - 1];
    //         }

    //         norders.pop();
    //         _orders.pop();
    //     }
    // }
    
    // function clearOrders() {
    //     uint256[] memory uorders = _ordersByUser[msg.sender];
    //     uint256 reverted;

    //     if (uorders.length > 0) {

    //     }
    // }

    // function _revertOrder(uint256 index) private {
    //     Order memory order = _orders[index];
        
    // }



    // function queryOrder(uint256 queryType, ) {

    // }

    function parseString(string memory value) external pure returns (uint256) {
        uint256 res = _parseNumber(value);

        return res;
    }

    function divide(string memory val1, string memory val2) external pure returns(uint256) {
        uint256 res1 = _parseNumber(val1);
        uint256 res2 = _parseNumber(val2);

        UD60x18 num1 = wrap(res1);
        UD60x18 num2 = wrap(res2);
        
        uint256 res3 = unwrap(div(num1, num2));

        return res3;
    }

    function _normalize(uint256 amount, uint256 scalar) private pure returns(uint256) {
        return scalar == 1 ? amount : amount * scalar;
    }

    function _denormalize(uint256 amount, uint256 scalar) private pure returns(uint256) {
        return scalar == 1 ? amount : amount / scalar;
    }

    function _computeScalar(uint256 decimals) private pure returns(uint256 scalar) {
        if (decimals == 18) {
            scalar = 1;
        } else {
            unchecked {
                scalar = 10 ** (18 - decimals);
            }
        }
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

    function _ensurePrice() private {
        if (block.timestamp - _lastPriceCheck < PRICE_CHECK_INTERVAL) {
            return;
        }

        _lastPriceCheck = block.timestamp;
        IPriceDAO oracle = IPriceDAO(_oracleAddr);

        string memory szPrice = oracle.getPrice();

        (uint256 price, bool success) = _tryParseNumber(szPrice);

        if (success) {
            _price = price;
        }

        _lastPriceCheck = block.timestamp;
    }

    function _fetchToken(address addr) private view returns(Token memory) {
        uint256 index = _tokenMap[addr];

        if (index == 0) {
            revert TokenNotListed();
        }

        return _tokens[index - 1];
    }

    function _fetchToken(uint256 index) private view returns(Token memory) {
        if (index == 0 || index >= _tokens.length) {
            revert TokenNotListed();
        }

        return _tokens[index - 1];
    }



    function _displayToken(uint256 index) private view returns(TokenDataModel memory) {
        Token memory token = _tokens[index];
        uint256 orderCount = _ordersByToken[token.addr].length;

        return TokenDataModel(
            index, token.name, token.sym, token.addr, 
            token.parityAddr, token.reward, 
            token.rewardThreshold, token.scheme, token.price, orderCount);
    }

    // function _getTokenId(address tokenAddr) {

    // }

    function _div(uint256 num1, uint256 num2) private pure returns(uint256) {
        UD60x18 n1 = wrap(num1);
        UD60x18 n2 = wrap(num2);

        return unwrap(div(n1, n2));
    }

    function _parseNumber(string memory value) private pure returns(uint256) {
        (uint256 num, bool success) = _tryParseNumber(value);

        if (!success) {
            revert FailedStringToNumberConversion();
        }

        return num;
    }

    function _tryParseNumber(string memory value) private pure returns(uint256, bool) {
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

        return (res, hasErr);
    }   
}