// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface ICreditBorrower {

    function askForRepay(uint256 amount) external;

    // total balance manage by borrower
    function totalBalance() external view returns (uint256);

    // balance that can be repay back now
    function freeBalance() external view returns (uint256);
}
