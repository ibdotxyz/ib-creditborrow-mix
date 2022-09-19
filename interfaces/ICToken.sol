// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ICToken {
    function borrow(uint256 amount) external returns (uint256);

    function repayBorrow(uint256 amount) external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);

    function estimateBorrowRatePerBlockAfterChange(uint256 change, bool repay)
        external
        view
        returns (uint256);

    function underlying() external view returns (address);
}
