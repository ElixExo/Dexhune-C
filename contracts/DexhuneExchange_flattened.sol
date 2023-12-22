// SPDX-License-Identifier: BSD-3-Clause
// File: contracts/libraries/DexhuneMath.sol


/// @title Direct port of mulDiv functions from PRBMath by Paul Razvan Berg
// Sources: 
// https://2π.com/21/muldiv/
// https://github.com/PaulRBerg/prb-math/tree/main/src/ud60x18
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

library DexhuneMath { 
    /// @dev The unit number, which the decimal precision of the fixed-point types.
    uint256 constant UNIT = 1e18;

    /// @dev The the largest power of two that divides the decimal value of `UNIT`. The logarithm of this value is the least significant
    /// bit in the binary representation of `UNIT`.
    uint256 constant UNIT_LPOTD = 262144;

    /// @dev The unit number inverted mod 2^256.
    uint256 constant UNIT_INVERSE = 78156646155174841979727994598816262306175212592076161876661_508869554232690281;

    error MulDiv18Overflow(uint256 x, uint256 y);
    error MulDivOverflow(uint256 x, uint256 y, uint256 denominator);

    function mul(uint256 x, uint256 y) internal pure returns(uint256 result) {
        return _mulDiv18(x, y);
    }

    function div(uint256 x, uint256 y) internal pure returns(uint256 result) {
        return _mulDiv(x, UNIT, y);
    }

    /// @notice Calculates x*y÷1e18 with 512-bit precision.
    ///
    /// @dev A variant of {mulDiv} with constant folding, i.e. in which the denominator is hard coded to 1e18.
    ///
    /// Notes:
    /// - The body is purposely left uncommented; to understand how this works, see the documentation in {mulDiv}.
    /// - The result is rounded toward zero.
    /// - We take as an axiom that the result cannot be `MAX_UINT256` when x and y solve the following system of equations:
    ///
    /// $$
    /// \begin{cases}
    ///     x * y = MAX\_UINT256 * UNIT \\
    ///     (x * y) \% UNIT \geq \frac{UNIT}{2}
    /// \end{cases}
    /// $$
    ///
    /// Requirements:
    /// - Refer to the requirements in {mulDiv}.
    /// - The result must fit in uint256.
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    /// @custom:smtchecker abstract-function-nondet
    function _mulDiv18(uint256 x, uint256 y) private pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly ("memory-safe") {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 == 0) {
            unchecked {
                return prod0 / UNIT;
            }
        }

        if (prod1 >= UNIT) {
            revert MulDiv18Overflow(x, y);
        }

        uint256 remainder;
        assembly ("memory-safe") {
            remainder := mulmod(x, y, UNIT)
            result :=
                mul(
                    or(
                        div(sub(prod0, remainder), UNIT_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, UNIT_LPOTD), UNIT_LPOTD), 1))
                    ),
                    UNIT_INVERSE
                )
        }
    }

    /// @notice Calculates x*y÷denominator with 512-bit precision.
    ///
    /// @dev Credits to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Notes:
    /// - The result is rounded toward zero.
    ///
    /// Requirements:
    /// - The denominator must not be zero.
    /// - The result must fit in uint256.
    ///
    /// @param x The multiplicand as a uint256.
    /// @param y The multiplier as a uint256.
    /// @param denominator The divisor as a uint256.
    /// @return result The result as a uint256.
    /// @custom:smtchecker abstract-function-nondet
    function _mulDiv(uint256 x, uint256 y, uint256 denominator) private pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512-bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly ("memory-safe") {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division.
        if (prod1 == 0) {
            unchecked {
                return prod0 / denominator;
            }
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert MulDivOverflow(x, y, denominator);
        }

        ////////////////////////////////////////////////////////////////////////////
        // 512 by 256 division
        ////////////////////////////////////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0].
        uint256 remainder;
        assembly ("memory-safe") {
            // Compute remainder using the mulmod Yul instruction.
            remainder := mulmod(x, y, denominator)

            // Subtract 256 bit number from 512-bit number.
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        unchecked {
            // Calculate the largest power of two divisor of the denominator using the unary operator ~. This operation cannot overflow
            // because the denominator cannot be zero at this point in the function execution. The result is always >= 1.
            // For more detail, see https://cs.stackexchange.com/q/138556/92363.
            uint256 lpotdod = denominator & (~denominator + 1);
            uint256 flippedLpotdod;

            assembly ("memory-safe") {
                // Factor powers of two out of denominator.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Get the flipped value `2^256 / lpotdod`. If the `lpotdod` is zero, the flipped value is one.
                // `sub(0, lpotdod)` produces the two's complement version of `lpotdod`, which is equivalent to flipping all the bits.
                // However, `div` interprets this value as an unsigned value: https://ethereum.stackexchange.com/q/147168/24693
                flippedLpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * flippedLpotdod;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
        }
    }
}
// File: contracts/utils/Ownable.sol


/// @title Abstract ownable inspired by OpenZeppelin's implementation
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

abstract contract Ownable {
    address public owner;

    error UnauthorizedAccount(address account);
    event TransferredOwnership(address oldOwner, address newOwner);

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
}
// File: contracts/interfaces/IPriceDAO.sol


/// @title Simple Interface for PriceDAO contracts
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

interface IPriceDAO {
    /**
     * Get the current price
     */
    function getPrice() external view returns (string memory);
}
// File: contracts/interfaces/IERC20.sol


/// @title Standard Interface for ERC20 tokens
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

pragma solidity ^0.8.22;

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);


    /**
     * @dev OPTIONAL Returns the name of the token
     */
    function name() external view returns (string memory);

    /**
     * @dev OPTIONAL Returns the symbol of the token
     */
    function symbol() external view returns (string memory);

    /**
     * @dev OPTIONAL Returns the amount of decimals supported by the token
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}
// File: contracts/DexhuneExchangeBase.sol


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





abstract contract DexhuneExchangeBase is Ownable {
    mapping(address => uint256) internal _avaxBalance; // Balance X
    mapping(address => uint256) internal _balances; // Balance Y
    mapping(address => uint256) internal _allocBalances; // Balance Z
    mapping(uint8 => uint256) private _scalars;

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Transfers
    function _sendToken(Token memory token, address targetAddr, uint256 amount) internal returns (bool) {
        try token.instance.transfer(targetAddr, amount) returns (bool success) {
            if (success) {
                _balances[token.addr] -= amount;
                emit TokenTransferred(amount, targetAddr, token.addr);
            }
            return success;
        } catch {
            return false;
        }
    }

     function _sendTokenAlloc(Token memory token, address targetAddr, uint256 amount) internal returns (bool) {
        try token.instance.transfer(targetAddr, amount) returns (bool success) {
            if (success) {                
                _balances[token.addr] -= amount;
                _allocBalances[token.addr] -= amount;
                emit TokenTransferred(amount, targetAddr, token.addr);
            }
            return success;
        } catch {
            return false;
        }
    }

    function _withdrawToken(Token memory token, address targetAddr, uint256 amount) internal returns (bool) {
        try token.instance.transferFrom(targetAddr, address(this), amount) returns (bool success) {
            if (success) {
                _balances[token.addr] += amount;
            }

            return success;
        } catch {
            return false;
        }
    }

    function _withdrawTokenAlloc(Token memory token, address targetAddr, uint256 amount) internal returns (bool) {
        bool success = _withdrawToken(token, targetAddr, amount);
        if (success) {
            _allocBalances[token.addr] += amount;
        }

        return success;
    }

    function _sendAVAX(Token memory token, address payable to, uint256 amount) internal returns(bool) {
        if (to.send(amount)) {
            emit AVAXTransferred(amount, to);
            _avaxBalance[token.addr] -= amount;
            return true;
        }

        return false;
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

    function _normalize(uint256 amount, uint8 decimals) internal returns(uint256) {
        return decimals == 1 ? amount : amount * _computeScalar(decimals);
    }

    function _denormalize(uint256 amount, uint8 decimals) internal returns(uint256) {
        return decimals == 1 ? amount : amount / _computeScalar(decimals);
    }

    function _computeScalar(uint8 decimals) internal returns(uint256 scalar) {
        scalar = _scalars[decimals];
    
        if (scalar == 0) {
            unchecked {
                _scalars[decimals] = scalar = 10 ** (18 - decimals);
            }
        }
    }
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Utils
    function _removeItem(uint256[] storage arr, uint256 index) internal returns(bool) {
        uint256 last = arr.length - 1;
        bool isLast = index == last;
        
        if (!isLast) {
            arr[index] = arr[last];
        }

        arr.pop();
        return !isLast;
    }

    function _removeItem(Order[] storage arr, uint256 index) internal returns(bool) {
        uint256 last = arr.length - 1;
        bool isLast = index == last;
        
        if (!isLast) {
            arr[index] = arr[last];
        }

        arr.pop();
        return !isLast;
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
        address addr;
        address parityAddr;
        
        PricingScheme scheme;

        uint256 reward;
        uint256 rewardThreshold;

        uint256 price;
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
        uint256 price;
        uint256 principal;
        uint256 pending;

        uint256 tokenIndex;
        uint256 userIndex;
    }

    error FailedStringToNumberConversion();
    error TokenAlreadyExists(address contractAddr);
    error TokenLimitReached();
    error TokenOrderLimitReachedRetryOrClear();
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
// File: contracts/DexhuneExchange.sol


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




contract DexhuneExchange is DexhuneExchangeBase {
    uint256 public listingCost = INITIAL_LISTING_COST;

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
    uint256 private constant MAX_ORDERS_PER_TOKEN = 10_000;
    uint256 private constant MAX_TOKEN_COUNT = 1_000_000;
    uint256 private constant ORDER_LIFESPAN = 40 seconds;
    uint256 private constant PRICE_CHECK_INTERVAL = 4 minutes;

    /// @dev Constant per thousand to increase the listing price by. Default value is 5, indicating 0.005% [0.005 * 1000]
    uint256 private constant LISTING_COST_INCREASE_BY_THOUSAND = 5;
    /// @dev Initial listing cost in DXH
    uint256 private constant INITIAL_LISTING_COST = 1000; // DXH
    /// @dev Maximum amount of listing cost allowed
    uint256 private constant MAX_LISTING_COST = 1_000_000;

    uint256 private constant ORDER_LOOP_LIMIT = 100;
    uint256 private constant CLEAR_ORDERS_USER_LIMIT = 50;
    
    
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
            _removeOrder(order, index);
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
        uint256 i; uint256 j; uint256 k;
        
        for (i = norders.length; i > 0 && k < ORDER_LOOP_LIMIT; i--) {
            k++;
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

            _removeOrder(order, n);
        }
    }

    function clearOrders() external {
        uint256[] storage uorders = _ordersByUser[msg.sender];
        bool userOnly = uorders.length > 0;

        uint256 reverted = 0;
        uint256 limit = userOnly ? CLEAR_ORDERS_USER_LIMIT : ORDER_LOOP_LIMIT;
        
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

    function clearTokenOrders(address tokenAddr) external {
        uint256[] storage torders = _ordersByToken[tokenAddr];
        
        uint256 n;
        uint256 i; uint256 j;
        uint256 reverted;
        uint256 timestamp = block.timestamp;

        Order memory order;

        for (i = torders.length; i > 0 && reverted < ORDER_LOOP_LIMIT; i--) {
            j = i - 1;

            n = torders[j];
            order = _orders[n];

            if (timestamp - order.created > ORDER_LIFESPAN) {
                if (_revertOrder(order, n)) {
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
        _removeOrder(order, index);
        emit OrderReverted(index, order.orderType, order.makerAddr);
        

        return true;
    }

    function _removeOrder(Order memory order, uint256 index) private {
        uint256 userIndex = order.userIndex;
        uint256 tokenIndex = order.tokenIndex;

        uint256[] storage uorders = _ordersByUser[order.makerAddr];
        uint256[] storage torders = _ordersByToken[order.tokenAddr];
        Order storage rOrder;

        if (_removeItem(uorders, userIndex)) {
            rOrder = _orders[uorders[userIndex]];
            rOrder.userIndex = userIndex;
        }

        if (_removeItem(torders, tokenIndex)) {
            rOrder = _orders[torders[tokenIndex]];
            rOrder.tokenIndex = tokenIndex;
        }

        if (_removeItem(_orders, index)) {
            rOrder = _orders[index];
            
            userIndex = rOrder.userIndex;
            tokenIndex = rOrder.tokenIndex;
            uorders = _ordersByUser[rOrder.makerAddr];
            torders = _ordersByToken[rOrder.tokenAddr];

            uorders[userIndex] = index;
            torders[tokenIndex] = index;
        }
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

        uint256[] storage torders = _ordersByToken[token.addr];
        uint256[] storage uorders = _ordersByUser[msg.sender];

        if (torders.length >= MAX_ORDERS_PER_TOKEN) {
            revert TokenOrderLimitReachedRetryOrClear();
        }

        uint256 index = _orders.length;
        Order memory order = Order(payable(msg.sender), token.addr, orderType, 
            block.timestamp, price, amount, pending, 
            torders.length, uorders.length);

        
        _orders.push(order);
        torders.push(index);
        uorders.push(index);

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

        if (listingCost != MAX_LISTING_COST) {
            uint256 lPrice = (listingCost * LISTING_COST_INCREASE_BY_THOUSAND) / 1000;
            listingCost += lPrice;

            if (listingCost > MAX_LISTING_COST) {
                listingCost = MAX_LISTING_COST;
            }
        }
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