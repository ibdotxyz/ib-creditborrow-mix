// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../interfaces/ICToken.sol";

contract MockCToken is ICToken {
    using SafeERC20 for IERC20;

    IERC20 private _underlying;
    mapping(address => uint256) private _borrowBalance;
    uint256 private _estimateBorrowRate;
    bool private borrowFailed;
    bool private repayFailed;

    constructor(address underlying_) {
        _underlying = IERC20(underlying_);
    }

    function underlying() external view returns (address) {
        return address(_underlying);
    }

    function borrow(uint256 amount) external returns (uint256) {
        if (borrowFailed) {
            return 1; // graceful failure
        }

        _borrowBalance[msg.sender] += amount;

        _underlying.safeTransfer(msg.sender, amount);
    }

    function repayBorrow(uint256 amount) external returns (uint256) {
        if (repayFailed) {
            return 1; // graceful failure
        }

        _borrowBalance[msg.sender] -= amount;

        _underlying.safeTransferFrom(msg.sender, address(this), amount);
    }

    function borrowBalanceCurrent(address account) external returns (uint256) {
        _underlying = _underlying; // silence the compiler

        return _borrowBalance[account];
    }

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256)
    {
        return _borrowBalance[account];
    }

    function estimateBorrowRatePerBlockAfterChange(uint256 change, bool repay)
        external
        view
        returns (uint256)
    {
        change;
        repay; // silence the compiler
        return _estimateBorrowRate;
    }

    function setEstimateBorrowRate(uint256 estimateBorrowRate_) external {
        _estimateBorrowRate = estimateBorrowRate_;
    }

    function setBorrowFailed(bool failed) external {
        borrowFailed = failed;
    }

    function setRepayFailed(bool failed) external {
        repayFailed = failed;
    }
}
