// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ICreditOfficer.sol";
import "../interfaces/ICreditBorrower.sol";

contract CreditBorrower is ICreditBorrower {
    using SafeERC20 for IERC20;

    address public admin;
    ICreditOfficer public creditOfficer;

    IERC20 internal constant dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    constructor(address _admin, address _creditOfficer) {
        require(address(dai) == ICreditOfficer(_creditOfficer).token(), "wrong borrowed token");
        admin = _admin;
        creditOfficer = ICreditOfficer(_creditOfficer);
        dai.approve(_creditOfficer, type(uint256).max);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    modifier onlyCreditOfficer() {
        require(msg.sender == address(creditOfficer));
        _;
    }

    /**
     * @notice Ask for Repay.
     * @dev Since Iron Bank is the senior debt, borrower should implement this function to allow credit officer to pull the asset prior.
     */
    function askForRepay(uint256 amount) external onlyCreditOfficer {
        uint256 daiBalance = dai.balanceOf(address(this));
        if (amount > daiBalance) {
            _unwind(amount - daiBalance);
        }
        creditOfficer.repay(amount);
    }

    function totalBalance() external view returns (uint256) {
        return IERC20(dai).balanceOf(address(this)) + balanceInWork();
    }

    function freeBalance() external view returns (uint256) {
        return IERC20(dai).balanceOf(address(this));
    }

    function borrow(uint256 amount) external onlyAdmin {
        creditOfficer.borrow(amount);
    }

    function repay(uint256 amount) external onlyAdmin {
        creditOfficer.repay(amount);
    }

    function work() external onlyAdmin {
        // TODO: put your business logic here.
    }

    function balanceInWork() public view returns (uint256) {
        // TODO: return the balance in work.
        return 0;
    }

    function _unwind(uint256 amount) internal {
        // TODO: unwind your borrowed position for repay.
    }
}
