// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ICreditOfficer.sol";
import "../interfaces/ICreditBorrower.sol";

contract CreditBorrower is Ownable, ICreditBorrower {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    ICreditOfficer public immutable creditOfficer;

    constructor(
        address _admin,
        IERC20 _token,
        ICreditOfficer _creditOfficer
    ) {
        require(
            address(_token) == _creditOfficer.borrowToken(),
            "wrong borrow token"
        );
        token = _token;
        creditOfficer = _creditOfficer;
        token.approve(address(_creditOfficer), type(uint256).max);

        transferOwnership(_admin);
    }

    modifier onlyCreditOfficer() {
        require(msg.sender == address(creditOfficer), "!creditOfficer");
        _;
    }

    /**
     * @notice Ask for Repay.
     * @dev Since Iron Bank is the senior debt, borrower should implement this function to allow credit officer to pull the asset prior.
     */
    function askForRepay(uint256 amount) external onlyCreditOfficer {
        uint256 daiBalance = token.balanceOf(address(this));
        if (amount > daiBalance) {
            _unwind(amount - daiBalance);
        }
        creditOfficer.repay(amount);
    }

    function totalBalance() external view returns (uint256) {
        return IERC20(token).balanceOf(address(this)) + balanceInWork();
    }

    function freeBalance() external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function borrow(uint256 amount) external onlyOwner {
        creditOfficer.borrow(amount);
    }

    function repay(uint256 amount) external onlyOwner {
        creditOfficer.repay(amount);
    }

    function work() external onlyOwner {
        // TODO: put your business logic here.
    }

    function balanceInWork() public view returns (uint256) {
        // TODO: return the balance in work.
        return 0;
    }

    function _unwind(uint256 amount) internal {
        // TODO: unwind your borrow position to repay.
    }
}
