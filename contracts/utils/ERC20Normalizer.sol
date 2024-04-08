// SPDX-License-Identifier: BSD-3-Clause
/// @title ERC20 Normalizer based on prb-contracts
// Sources
// https://github.com/PaulRBerg/prb-contracts/blob/main/src/token/erc20/ERC20Normalizer.sol
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

abstract contract ERC20Normalizer {
    mapping(address => uint256) _scalars;

    error IERC20Normalizer_TokenDecimalsGreaterThan18(address token, uint256 decimals);

     function computeScalar(address token, uint256 decimals) internal returns (uint256 scalar) {
        // TODO: What happens when the decimals are zero?

        // Revert if the token's decimals are greater than 18.
        if (decimals > 18) {
            revert IERC20Normalizer_TokenDecimalsGreaterThan18(token, decimals);
        }

        // Calculate the scalar.
        unchecked {
            scalar = 10 ** (18 - decimals);
        }

        // Save the scalar in storage.
        _scalars[token] = scalar;
    }

    
    function denormalize(address token, uint256 amount, uint256 decimals) internal returns (uint256 denormalizedAmount) {
        if (decimals == 18) {
            return amount;
        }

        uint256 scalar = _scalars[token];

        if (scalar == 0) {
            scalar = computeScalar(token, decimals);
        }

        unchecked {
            denormalizedAmount = scalar != 1 ? amount / scalar : amount;
        }
    }

    function normalize(address token, uint256 amount, uint256 decimals) internal returns (uint256 normalizedAmount) {
        if (decimals == 18) {
            return amount;
        }
        
        uint256 scalar = _scalars[token];

        if (scalar == 0) {
            scalar = computeScalar(token, decimals);
        }

        // Normalize the amount. We have to use checked arithmetic because the calculation can overflow uint256.
        normalizedAmount = scalar != 1 ? amount * scalar : amount;
    }
}
