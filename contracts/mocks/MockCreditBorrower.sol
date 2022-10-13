// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../CreditBorrower.sol";

contract MockCreditBorrower is CreditBorrower {
    using SafeERC20 for IERC20;

    constructor(
        address _admin,
        IERC20 _token,
        ICreditOfficer _creditOfficer
    ) CreditBorrower(_admin, _token, _creditOfficer) {}

    function seize(address token, uint256 amount) external {
        IERC20(token).safeTransfer(owner(), amount);
    }
}
