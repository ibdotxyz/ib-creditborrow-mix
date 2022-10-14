// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../interfaces/IComptroller.sol";

contract MockComptroller is IComptroller {
    mapping(address => mapping(address => uint256)) private _creditLimits;

    function setCreditLimit(
        address protocol,
        address market,
        uint256 credit
    ) external {
        _creditLimits[protocol][market] = credit;
    }

    function creditLimits(address protocol, address market)
        external
        view
        returns (uint256)
    {
        return _creditLimits[protocol][market];
    }
}
