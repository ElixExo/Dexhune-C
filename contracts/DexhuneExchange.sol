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

pragma solidity ^0.8.22;
import "./interfaces/IERC20.sol";
import "./interfaces/IPriceDAO.sol";
import "./DexhuneExchangeBase.sol";

contract DexhuneExchange is DexhuneExchangeBase {
    uint256 public listingCost = INITIAL_LISTING_PRICE;

    Token[] private _tokens;
    Order[] private _orders;

    Order[] public orders = _orders;

    mapping(address => uint256) private _tokenMap;
    mapping(address => uint256[]) private _ordersByToken;
    mapping(address => uint256[]) private _ordersByUser;
    
    uint256 private _price;
    uint256 private _lastPriceCheck;
    IPriceDAO private _oracle;

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

    function getBalance() external view returns(uint256) {
        return address(this).balance;
    }

    function queryBalance(address tokenAddr, bool isAVAX) external view returns (uint256) {
        if (isAVAX) {
            return _avaxBalance[tokenAddr];
        } else {
            return _balances[tokenAddr];
        }
    }

    function viewPrice() external view returns (uint256) {
        return _price;
    }

    function assignPriceDAO(address addr) external ownerOnly {
        _oracle = IPriceDAO(addr);
        _ensurePrice();

        emit AssignedPriceDAO(addr);
    }

    function viewToken(address tokenAddr) external view returns (TokenDataModel memory) {
        uint256 index = _tokenMap[tokenAddr];
        return _displayToken(index);
    }

    function viewTokenByIndex(uint256 tokenNo) external view returns (TokenDataModel memory) {
        return _displayToken(tokenNo);
    }

    function viewOrder(uint256 index) external view returns (Order memory) {
        if (index >= _orders.length) {
            revert OrderDoesNotExist();
        }

        return _orders[index];
    }

    function viewOrderByToken(address tokenAddr, uint256 index) external view returns (Order memory) {
        uint256[] memory indexes = _ordersByToken[tokenAddr];

        if (index >= indexes.length) {
            revert OrderDoesNotExist();
        }

        uint256 n = indexes[index];
        return _orders[n];
    }

    function viewOrderByMaker(address makerAddr, uint256 index) external view returns(Order memory) {
        uint256[] memory indexes = _ordersByUser[makerAddr];

        if (index >= indexes.length) {
            revert OrderDoesNotExist();
        }

        uint256 n = indexes[index];
        return _orders[n];
    }

    function listToken(address tokenAddr, uint256 reward, uint256 rewardThreshold, string memory price) external {
        _listToken(tokenAddr, PricingScheme.Relative, reward, rewardThreshold, address(0), price);
    }

    function listParityToken(address tokenAddr, address parityAddr, uint256 reward, uint256 rewardThreshold) external {
        _listToken(tokenAddr, PricingScheme.Parity, reward, rewardThreshold, parityAddr, "");
    }

    function _listToken(address tokenAddr, PricingScheme scheme, uint256 reward, uint256 rewardThreshold, address parityAddr, string memory price) private {
        bool isDefault = _tokens.length == 0;

        if (isDefault) {
            if (msg.sender != owner) {
                revert OnlyOwnerMustSetDefaultToken();
            }

            scheme = PricingScheme.Relative;
        }

        address addr = tokenAddr;
        uint256 index = _tokenMap[addr];

        if (index != 0 && _tokens.length > 0) {
            revert TokenAlreadyExists(addr);
        }

        if (_tokens.length >= MAX_TOKEN_COUNT) {
            revert TokenLimitReached();
        }

        uint256 nPrice = 0;

        if (scheme == PricingScheme.Relative) {
            if (!isDefault) {
                nPrice = _parseNumber(price);
            } else {
                nPrice = 1e18;
            }
        }

        _chargeForListing();

        _prepareToken(addr, nPrice, scheme, 
            parityAddr, reward, rewardThreshold);
    }
    
    function createBuyOrder(address tokenAddr) external payable {
        uint256 amount = msg.value;

        if (amount <= 0) {
            revert RejectedZeroAmount();
        }

        Token storage token = _fetchStorageToken(tokenAddr);
        _avaxBalance[tokenAddr] += amount;
        

        _createOrder(token, true, amount);
    }

    function createSellOrder(address tokenAddr, uint256 amount) external {
        if (amount <= 0) {
            revert RejectedZeroAmount();
        }

        Token storage token = _fetchStorageToken(tokenAddr);
        if (!_withdrawTokenAlloc(token, msg.sender, amount)) {
            revert DepositFailed();
        }

        _createOrder(token, false, amount);
    }

    function deposit(address tokenAddr) external payable {
        _avaxBalance[tokenAddr] += msg.value;
    }

    function depositToken(address tokenAddr, uint256 amount) external {
        _depositToken(tokenAddr, msg.sender, amount);
    }

    function depositTokenFrom(address tokenAddr, address fromAddress, uint256 amount) external {
        _depositToken(tokenAddr, fromAddress, amount);
    }

    function updateTokenBalance(address tokenAddr) external {
        Token memory token = _fetchToken(tokenAddr);

        uint256 balance = token.instance.balanceOf(address(this));
        _balances[tokenAddr] = balance;
    }

    function takeBuyOrder(address tokenAddr, uint256 amount) external {
        Token memory token = _fetchToken(tokenAddr);

        Order storage order;
        uint256 orderIndex;
        bool success;

        (success, orderIndex) = _findSuitableOrder(tokenAddr, amount);

        if (!success) {
            revert NoSuitableOrderFound();
        }

        if (!_withdrawTokenAlloc(token, msg.sender, amount)) {
            revert DepositFailed();
        }

        order = _orders[orderIndex];
        _takeOrder(order, true, orderIndex, amount, tokenAddr);
    }

    function takeSellOrder(address tokenAddr) external payable {
        uint256 amount = msg.value;

        Order storage order;
        uint256 orderIndex;
        bool success;

        (success, orderIndex) = _findSuitableOrder(tokenAddr, amount);

        if (!success) {
            revert NoSuitableOrderFound();
        }


        _avaxBalance[tokenAddr] += amount;

        order = _orders[orderIndex];
        _takeOrder(order, false, orderIndex, amount, tokenAddr);
    }

    function _depositToken(address tokenAddr, address fromAddress, uint256 amount) private {
        Token memory token = _fetchToken(tokenAddr);

        if (!_withdrawToken(token, fromAddress, amount)) {
            revert DepositFailed();
        }
    }

    function _findSuitableOrder(address tokenAddr, uint256 amount) private view returns (bool success, uint256 index) {
        Order memory order;
        uint256[] storage norders = _ordersByToken[tokenAddr];

        bool found;

        uint256 i; uint256 j;

        for (i = norders.length; i > 0 && !found; i--) {
            j = i - 1;
            uint256 n = norders[j];
            order = _orders[n];

            if (order.pending == amount) {
                found = true;
                index = n;
            } else if (!found && order.pending >= amount) {
                found = true;
                index = n;
            }
        }

        return (found, index);
    }


    function _takeOrder(Order storage order, bool orderType, uint256 index, uint256 amount, address tokenAddr) private {
        Token memory token = _fetchToken(tokenAddr);
        order = _orders[index];
            
        uint256 principal = order.principal;
        uint256 pending = order.pending;

        bool isPartial = pending != amount;
        address payable makerAddr = order.makerAddr;
        uint256 quotient = 1;
        uint256 amt = amount;

        uint8 dec = token.dec;
        if (isPartial) {
            if (orderType) {
                // Normalize to maximize precision
                uint256 nPending = _normalize(pending, dec);
                uint256 nAmount = _normalize(amount, dec);

                quotient = _div(nAmount, nPending);
            } else {
                quotient = _div(amount, pending);
            }

            principal = _mul(order.principal, quotient);
        }
        
        _makeOrderPayments(order, token, amt, principal);
        uint256 tokenDelta = orderType ? amt : principal;

        if (isPartial) {
            order.pending -= amount;
            order.principal -= principal;
        } else {
            _removeItem(_orders, index);
        }

        _rewardTaker(token, tokenDelta);

        emit OrderTaken(index, orderType, makerAddr, 
            msg.sender, tokenAddr, amt, isPartial);
    }

    function _rewardTaker(Token memory token, uint256 amount) private {
        uint256 reward = token.reward;
        bool canReward = reward > 0 && amount >= token.rewardThreshold;

        if (canReward) {
            uint256 rem = _balances[token.addr] - _allocBalances[token.addr];

            if (rem > reward) {
                if (!_sendToken(token, msg.sender, reward)) {
                    revert FailedToSendReward();
                }   
            }
        }
    }

    function _makeOrderPayments(Order memory order, Token memory token, uint256 amount, uint256 principal) private {
        uint256 native;
        uint256 tokenDelta;
        address payable avaxAddr;
        address payable tkAddr;

        if (order.orderType) {
            native = principal;
            tokenDelta = amount;

            avaxAddr = payable(msg.sender);
            tkAddr = order.makerAddr;
        } else {
            native = amount;
            tokenDelta = principal;

            avaxAddr = order.makerAddr;
            tkAddr = payable(msg.sender);
        }

        if (!_sendTokenAlloc(token, tkAddr, tokenDelta)) {
            revert FailedToTakeOrder();
        }

        if (!_sendAVAX(token, avaxAddr, native)) {
            revert FailedToTakeOrder();
        }
    }

    function settleOrders(address tokenAddr, bool orderType) external {
        Token memory token = _fetchToken(tokenAddr);

        uint256[] storage norders = _ordersByToken[token.addr];
        Order storage order;

        bool settled;
        uint256 balance;
        uint256 i; uint256 j;
        
        for (i = norders.length; i > 0; i--) {
            j = i - 1;

            uint256 n = norders[j];
            order = _orders[n];
            balance = orderType ? _balances[tokenAddr] : _avaxBalance[tokenAddr];

            if (balance <= 0) {
                break;
            }

            if (order.orderType != orderType) {
                continue;
            }

            if (orderType) {
                settled = _settleBuyOrder(token, order, j, balance);
            } else {
                settled = _settleSellOrder(token, order, j, balance);
            }

            if (!settled) {
                continue;
            }
            
            _removeItem(norders, j);
            _removeItem(_orders, n);
        }
    }

    function clearOrders() external {
        uint256[] storage uorders = _ordersByUser[msg.sender];
        bool userOnly = uorders.length > 0;

        uint256 reverted = 0;
        uint256 limit = userOnly ? CLEAR_ORDERS_USER_LIMIT : CLEAR_ORDERS_LIMIT;
        
        uint256 n;
        uint256 timestamp = block.timestamp;
        Order memory order;

        if (_orders.length <= 0) {
            return;
        }

        uint256 i; uint256 j;

        if (userOnly) {
            for (i = uorders.length; i > 0 && reverted <= limit; i--) {
                j = i - 1;

                n = uorders[j];
                order = _orders[n];
                
                if (timestamp - order.created > ORDER_LIFESPAN) {
                    if (_revertOrder(order, n)) {
                        _removeItem(uorders, j);
                        reverted++;
                    }
                }
            }

            return;
        }

        for (i = _orders.length; i > 0 && reverted <= limit; i--) {
            j = i - 1;
            order = _orders[j];

            if (timestamp - order.created > ORDER_LIFESPAN) {
                if (_revertOrder(order, j)) {
                    reverted++;
                }
            }
        }
    }

    function _revertOrder(Order memory order, uint256 index) private returns (bool) {
        Token memory token = _fetchToken(order.tokenAddr);

        if (order.orderType) { // Buy
            if (!_sendAVAX(token, order.makerAddr, order.principal)) {
                return false;
            }
        } else {
            if (!_sendTokenAlloc(token, order.makerAddr, order.principal)) {
                return false;
            }
        }

        // TODO: Review Order events
        emit OrderReverted(index, order.orderType, order.makerAddr);
        _removeItem(_orders, index);

        return true;
    }

    function _createOrder(Token storage token, bool orderType, uint256 amount) private {
        uint256 price;

        if (token.scheme == PricingScheme.Relative) {
            _ensurePrice();
            price = _div(_price, token.price);

        } else if (token.scheme == PricingScheme.Parity) {
            bool canUpdate = token.lastPriceCheck == 0 || block.timestamp - token.lastPriceCheck >= PRICE_CHECK_INTERVAL;

            if (canUpdate) {
                Token memory dxh = _tokens[0];
                IERC20 tokenInst = token.instance;
                IERC20 dxhInst = dxh.instance;


                uint256 tBalance = tokenInst.balanceOf(token.parityAddr);
                uint256 dxhBalance = dxhInst.balanceOf(token.parityAddr);

                tBalance = _normalize(tBalance, token.dec);
                dxhBalance = _normalize(dxhBalance, dxh.dec);

                token.price = price = _div(dxhBalance, tBalance);
                token.lastPriceCheck = block.timestamp;
            } else {
                price = token.price;
            }
        }

        uint256 pending;

        if (orderType) { // Buy
            pending = _denormalize(_mul(amount, price), token.dec);
        } else {
            pending = _div(_normalize(amount, token.dec), price);
        }


        Order memory order = Order(payable(msg.sender), token.addr, orderType, block.timestamp, price, amount, pending);
        _orders.push(order);

        uint256 index = _orders.length - 1;
        _ordersByUser[msg.sender].push(index);
        _ordersByToken[token.addr].push(index);

        emit OrderCreated(index, orderType, token.addr, amount, price);
    }

    
    function _prepareToken(address addr, uint256 price, PricingScheme scheme, address parityAddr, uint256 reward, uint256 rewardThreshold) private {
        IERC20 inst = IERC20(addr);
        
        string memory name;
        string memory sym;
        uint256 balance;
        uint8 decimals;

        try inst.balanceOf(address(this)) returns (uint256 _bal) {
            balance = _bal;

            try inst.decimals() returns (uint8 _dec) {
                decimals = _dec;
            } catch {
                decimals = NATIVE_TOKEN_DECIMALS;
            }

            if (decimals > NATIVE_TOKEN_DECIMALS) {
                revert TokenNotSupported_TooManyDecimals();
            }

            try inst.name() returns (string memory _name) {
                name = _name;
            } catch {}

            try inst.symbol() returns (string memory _sym) {
                sym = _sym;
            } catch {}
        } catch {
            revert InvalidTokenContract();
        }

        Token memory token = Token(
            name, sym, decimals, 
            addr, parityAddr,
            scheme, reward, rewardThreshold,
            price, 0, inst
        );

        _tokens.push(token);
        _tokenMap[token.addr] = _tokens.length;
        _balances[token.addr] = balance;

        emit TokenListed(token.name, token.sym, token.scheme, token.addr, _tokens.length);
    }

    function _settleBuyOrder(Token memory token, Order storage order, uint256 index, uint256 balance) private returns (bool) {
        bool success;
        uint256 amount;

        bool isPartial = balance < order.pending;
                
        if (isPartial) {
            amount = balance;
        } else {
            amount = order.pending;
        }

        if (_allocBalances[token.addr] >= amount) {
            success = _sendTokenAlloc(token, order.makerAddr, amount);
        } else {
            success = _sendToken(token, order.makerAddr, amount);
        }

        if (!success) {
            return false;
        }

        if (isPartial) {
            uint256 quotient = _div(_normalize(amount, token.dec), _normalize(order.pending, token.dec));
            order.principal -= _mul(order.principal, quotient);//_div(_normalize(order.pending, token.dec), order.price);
            order.pending -= amount;
        }
        

        emit OrderSettled(index, order.orderType, order.makerAddr, isPartial);
        return !isPartial;
    }

    function _settleSellOrder(Token memory token, Order storage order, uint256 index, uint256 balance) private returns (bool) {
        uint256 amount;
        bool isPartial = balance < order.pending;

        if (isPartial) {
            amount = balance;
        } else {
            amount = order.pending;
        }

        if (!_sendAVAX(token, order.makerAddr, amount)) {
            return false;    
        }

        if (isPartial) {
            uint256 quotient = _div(amount, order.pending);

            order.principal -= _mul(order.principal, quotient);
            order.pending -= amount;
            // order.principal = _denormalize(_mul(order.pending, order.price), token.dec);
        }

        emit OrderSettled(index, order.orderType, order.makerAddr, isPartial);
        return !isPartial;
    }

    function _chargeForListing() private {
        if (_tokens.length == 0) {
            return;
        }
        
        if (!_withdrawToken(_tokens[0], msg.sender, listingCost)) {
            revert InsufficientBalanceForListing(listingCost);
        }
        
        uint256 lPrice = (listingCost * LISTING_PRICE_INCREASE_BY_THOUSAND) / 1000;
        listingCost += lPrice;
    }

    function _ensurePrice() private {
        if (_lastPriceCheck != 0 && block.timestamp - _lastPriceCheck < PRICE_CHECK_INTERVAL) {
            return;
        }

        string memory szPrice = _oracle.getPrice();

        (uint256 price, bool success) = _tryParseNumber(szPrice);

        if (success) {
            _price = price;
        }

        _lastPriceCheck = block.timestamp;   
    }

    function _fetchToken(address addr) private view returns(Token memory) {
        uint256 index = _tokenMap[addr];

        if (index == 0 || index > _tokens.length) {
            revert TokenNotListed();
        }

        return _tokens[index - 1];
    }

    function _fetchStorageToken(address addr) private view returns(Token storage) {
        uint256 index = _tokenMap[addr];

        if (index == 0 || index > _tokens.length) {
            revert TokenNotListed();
        }

        return _tokens[index - 1];
    }

    function _displayToken(uint256 index) private view returns(TokenDataModel memory) {
        if (index == 0 || index > _tokens.length) {
            revert TokenNotListed();
        }

        Token memory token = _tokens[index - 1];
        uint256 orderCount = _ordersByToken[token.addr].length;

        return TokenDataModel(
            index, token.name, token.sym, token.addr, 
            token.parityAddr, token.reward, 
            token.rewardThreshold, token.scheme, token.price, orderCount);
    }
}