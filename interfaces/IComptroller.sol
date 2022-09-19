// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IComptroller {
    function creditLimits(address protocol, address market)
        external
        view
        returns (uint256);
}
