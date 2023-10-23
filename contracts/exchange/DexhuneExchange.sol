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
import "./DexhuneExchangeBase.sol";
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

contract DexhuneExchange is DexhuneExchangeBase {
    uint256 listingCost = INITIAL_LISTING_PRICE;

    Token[] private _tokens;
    Order[] private _orders;

    mapping(address => uint256) private _tokenMap;
    mapping(address => uint256[]) private _ordersByToken;
    mapping(address => uint256[]) private _ordersByUser;

    address private _dxhAddr;
    address private _oracleAddr;
    
    uint256 _price;
    uint256 _lastPriceCheck;

    uint8 private constant NATIVE_TOKEN_DECIMALS = 18;
    uint256 private constant MAX_ORDER_COUNT = 100_000;
    uint256 private constant MAX_TOKEN_COUNT = 1_000_000;
    uint256 private constant ORDER_LIFESPAN = 40 seconds;
    uint256 private constant PRICE_CHECK_INTERVAL = 4 minutes;

    uint256 private constant LISTING_PRICE_INCREASE_BY_THOUSAND = 5;
    uint256 private constant INITIAL_LISTING_PRICE = 1000; // DXH
    uint256 private constant MAX_LISTING_FEE = 1_000_000;

    uint256 private constant CLEAR_ORDERS_USER_LIMIT = 50;
    uint256 private constant CLEAR_ORDERS_LIMIT = 100;
    
    constructor() {
        owner = msg.sender;
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

    function getBalance() external view returns(uint256) {
        return address(this).balance;
    }

    function queryBalance(address tokenAddr, bool isAVAX) external view returns (uint256) {
        Token memory token = _fetchToken(tokenAddr);

        if (isAVAX) {
            return token.xBalance;
        } else {
            return token.yBalance;
        }
    }

    function listToken(address tokenAddr, PricingScheme scheme, uint256 reward, uint256 rewardThreshold, address parityAddr, string memory price) external {
        if (_tokens.length == 0) {
            if (msg.sender != owner) {
                revert OnlyOwnerMustSetDefaultToken();
            }
        }

        address addr = tokenAddr;
        uint256 index = _tokenMap[addr];

        if (index != 0 && _tokens.length > 0) {
            revert TokenAlreadyExists(addr);
        }

        if (_tokens.length >= MAX_TOKEN_COUNT) {
            revert TokenLimitReached();
        }

        IERC20 inst;
        string memory name;
        string memory sym;
        uint8 dec; uint256 scalar;

        (inst, name, sym, dec, scalar) = _prepareToken(addr);


        uint256 nPrice = _parseNumber(price);

        if (parityAddr != address(0) && nPrice > 0) {
            revert ParityShouldNotHavePrice();
        }

        _chargeForListing();

        Token memory token = Token(
            name, sym, dec, scalar, 
            addr, parityAddr,
            scheme, reward, rewardThreshold,
            nPrice, 0, 0, 0, inst
        );

        _tokens.push(token);
        _tokenMap[token.addr] = _tokens.length - 1;
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

    function deposit(address tokenAddr) external payable {
        Token memory token = _fetchToken(tokenAddr);
        uint256 amount = msg.value;

        token.xBalance += amount;
    }

    function depositToken(address tokenAddr, address fromAddress, uint256 amount) external {
        Token memory token = _fetchToken(tokenAddr);

        if (!_withdrawToken(token.instance, fromAddress, amount)) {
            revert DepositFailed();
        }

        token.yBalance += amount;
    }

    function takeBuyOrder(address tokenAddr, uint256 amount) external {
        Token memory token = _fetchToken(tokenAddr);

        Order memory order;
        uint256 orderIndex;
        bool success;

        (success, order, orderIndex) = _findSuitableOrder(tokenAddr, amount);

        if (!success) {
            revert NoSuitableOrderFound();
        }

        if (!_withdrawToken(token.instance, tokenAddr, amount)) {
            revert DepositFailed();
        }

        _takeOrder(order, true, orderIndex, amount, tokenAddr);
    }

    function takeSellOrder(address tokenAddr) external payable {
         uint256 amount = msg.value;

        Order memory order;
        uint256 orderIndex;
        bool success;

        (success, order, orderIndex) = _findSuitableOrder(tokenAddr, amount);

        if (!success) {
            revert NoSuitableOrderFound();
        }

        _takeOrder(order, true, orderIndex, amount, tokenAddr);
    }

    function _findSuitableOrder(address tokenAddr, uint256 amount) private view returns (bool success, Order memory, uint256) {
        Order memory order;
        uint256[] storage norders = _ordersByToken[tokenAddr];

        bool found;
        uint256 index;

        for (uint256 i = norders.length - 1; i >= 0; i--) {
            uint256 n = norders[i];
            order = _orders[n];

            if (order.pending == amount) {
                found = true;
                index = i;
                break;
            } else if (!found && order.pending >= amount) {
                found = true;
                index = i;
            }
        }

        return (found, order, index);
    }


    function _takeOrder(Order memory order, bool orderType, uint256 index, uint256 amount, address tokenAddr) private {
        Token memory token = _fetchToken(tokenAddr);

        order = _orders[index];
        bool isPartial = order.pending != amount;
    
        uint256 delta = order.pending - amount;
        uint256 principalDelta = order.principal;
        

        if (isPartial) {
            uint256 nPrice = _normalize(token.price, NATIVE_TOKEN_DECIMALS);
            uint256 nDelta = _normalize(delta, token.dec);
            principalDelta = _denormalize(nDelta / nPrice, token.dec);
        }

        address payable avaxAddr;
        address payable tkAddr;

        if (orderType) {
            avaxAddr = payable(msg.sender);
            tkAddr = order.makerAddr;
        } else {
            avaxAddr = order.makerAddr;
            tkAddr = payable(msg.sender);
        }


        if (!_sendToken(token.instance, tkAddr, principalDelta)) {
            revert FailedToTakeOrder();
        }

        if (!_sendAVAX(avaxAddr, delta)) {
            revert FailedToTakeOrder();
        }

        if (isPartial) {
            order.pending -= delta;
            order.principal -= principalDelta;
        } else {
            _removeItem(_orders, index);
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
            
            _removeItem(norders, i);
            _removeItem(_orders, n);
        }
    }

    function clearOrders() external {
        uint256[] storage uorders = _ordersByUser[msg.sender];
        bool userOnly = uorders.length > 0;

        uint256 reverted;
        uint256 limit = userOnly ? CLEAR_ORDERS_USER_LIMIT : CLEAR_ORDERS_LIMIT;
        
        uint256 n;
        uint256 timestamp = block.timestamp;
        Order memory order;

        if (_orders.length <= 0) {
            return;
        }
        

        if (userOnly) {
            for (uint256 i = uorders.length - 1; i >= 0 && reverted <= limit; i--) {
                n = uorders[i];
                order = _orders[n];
                
                if (timestamp - order.created > ORDER_LIFESPAN) {
                    if (_revertOrder(order, n)) {
                        _removeItem(uorders, i);
                        reverted++;
                    }
                }
            }

            return;
        }

        for (uint256 i = _orders.length - 1; i >= 0 && reverted <= limit; i--) {
            order = _orders[i];

            if (timestamp - order.created > ORDER_LIFESPAN) {
                if (_revertOrder(order, n)) {
                    reverted++;
                }
            }
        }
    }

    function _revertOrder(Order memory order, uint256 index) private returns (bool) {
        if (order.orderType) { // Buy
            if (!_sendAVAX(order.makerAddr, order.principal)) {
                return false;
            }
        } else {
            Token memory token = _fetchToken(order.tokenAddr);
            if (!_sendToken(token.instance, order.makerAddr, order.principal)) {
                return false;
            }
        }

        _removeItem(_orders, index);

        return true;
    }

    function _createOrder(Token memory token, bool orderType, uint256 amount) private {
        uint256 price;

        if (token.scheme == PricingScheme.Relative) {
            _ensurePrice();
            price = _div(_price, token.price);
        } else if (token.scheme == PricingScheme.Parity) {
            bool canUpdate = block.timestamp - token.lastPriceCheck >= PRICE_CHECK_INTERVAL;

            if (canUpdate) {
                Token memory dxh = _tokens[0];
                IERC20 tokenInst = token.instance;
                IERC20 dxhInst = dxh.instance;


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

        Order memory order = Order(payable(msg.sender), token.addr, orderType, block.timestamp, reward, price, amount, pending);
        _orders.push(order);

        uint256[] storage uorders = _ordersByUser[msg.sender];
        uint256[] storage torders = _ordersByToken[token.addr];

        uint256 index = _orders.length - 1;
        uorders.push(index);
        torders.push(index);
    }

    
    function _prepareToken(address addr) private view returns(IERC20, string memory, string memory, uint8, uint256) {
        IERC20 inst = IERC20(addr);
        
        string memory name;
        string memory sym;
        uint256 scalar;
        uint8 decimals;

        try inst.balanceOf(address(this)) {
            try inst.decimals() returns (uint8 _dec) {
                decimals = _dec;
            } catch {
                decimals = NATIVE_TOKEN_DECIMALS;
            }

            if (decimals > NATIVE_TOKEN_DECIMALS) {
                revert TokenNotSupported_TooManyDecimals();
            }

            scalar = _computeScalar(decimals);

            try inst.name() returns (string memory _name) {
                name = _name;
            } catch {}

            try inst.symbol() returns (string memory _sym) {
                sym = _sym;
            } catch {}
        } catch {
            revert InvalidTokenContract();
        }

        return (inst, name, sym, decimals, scalar);
    }

    function _settleBuyOrder(Token memory token, Order memory order, uint256 balance) private returns (bool settled, uint256 remBalance) {
        uint256 amount;
        bool isPartial = balance < order.pending;
        
        if (isPartial) {
            amount = balance;
        } else {
            amount = order.pending;
        }

        // IERC20 inst = IERC20(token.addr);
        IERC20 inst = token.instance;
        

        try inst.transfer(order.makerAddr, amount) {
            balance -= amount;

            if (isPartial) {
                order.pending -= amount;

                uint256 pending = _normalize(order.pending, token.dec);
                uint256 price = _normalize(order.price, NATIVE_TOKEN_DECIMALS);

                order.principal = _denormalize(pending / price, token.dec);
            }
        } catch {
            return (false, balance);
        }

        return (!isPartial, balance);
    }

    function _settleSellOrder(Token memory token, Order memory order, uint256 balance) private returns (bool settled, uint256 remBalance) {
        uint256 amount;
        bool isPartial = balance < order.pending;

        if (isPartial) {
            amount = balance;
        } else {
            amount = order.pending;
        }

        if (_sendAVAX(order.makerAddr, amount)) {
            balance -= amount;

            if (isPartial) {
                order.pending -= amount;

                uint256 pending = _normalize(order.pending, token.dec);
                uint256 price = _normalize(order.price, NATIVE_TOKEN_DECIMALS);

                order.principal = _denormalize(pending / price, token.dec);
            }

            return (true, balance);
        }
        
        return (false, balance);
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

    function _chargeForListing() private {
         Token memory def = _tokens[0];
        
        if (!_withdrawToken(def.instance, msg.sender, listingCost)) {
            revert InsufficientBalanceForListing(listingCost);
        }
        
        uint256 lPrice = (listingCost * LISTING_PRICE_INCREASE_BY_THOUSAND) / 1000;
        listingCost += lPrice;
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

        return _fetchToken(index);
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