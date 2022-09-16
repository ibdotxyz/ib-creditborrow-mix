// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../interfaces/ICreditOfficer.sol";
import "../../interfaces/ICreditBorrower.sol";
import "../../interfaces/IComptroller.sol";
import "../../interfaces/ICToken.sol";


contract CreditOfficer is ICreditOfficer, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public admin;
    address public guardian;
    IComptroller public comptroller;
    ICToken public ctoken;
    IERC20 public underlyingToken;

    ICreditBorrower public borrower;

    constructor(
        address _admin,
        address _comptroller,
        address _ctoken
    ) {
        admin = _admin;
        comptroller = IComptroller(_comptroller);
        ctoken = ICToken(_ctoken);
        underlyingToken = IERC20(ICToken(_ctoken).underlying());
        underlyingToken.approve(_ctoken, type(uint256).max);
    }

    /**
     * @notice Borrow from Iron Bank.
     * @param amount The amount of token to borrow.
     */
    function borrow(uint256 amount) external onlyBorrower nonReentrant whenNotPaused {
        ctoken.borrow(amount);
        underlyingToken.transfer(address(borrower), amount);
        require(borrower.totalBalance() >= ctoken.borrowBalanceStored(address(this)), "shortfall");
    }

    /**
     * @notice Repay to Iron Bank.
     * @param amount The amount of the token being repaid.
     */
    function repay(uint256 amount) external onlyBorrower nonReentrant {
        uint256 repayAmount;
        if (amount == type(uint256).max) {
            repayAmount = ctoken.borrowBalanceCurrent(address(this));
        } else {
            repayAmount = amount;
        }
        underlyingToken.transferFrom(address(borrower), address(this), repayAmount);
        ctoken.repayBorrow(amount);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @notice Set the borrower.
     */
    function setBorrower(address _borrower) external onlyAdmin {
        borrower = ICreditBorrower(_borrower);
    }

    /**
     * @notice Pause borrowing.
     */
    function pause() external {
        require(msg.sender == admin || msg.sender == guardian, "not authorized");
        _pause();
    }

    /**
     * @notice Unpause borrowing.
     */
    function unpause() external onlyAdmin {
        _unpause();
    }

    /**
     * @notice Ask for Repay.
     */
    function askForRepay(uint256 amount) external onlyAdmin {
        borrower.askForRepay(amount);
    }


    /* ========== MODIFIERS ========== */

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    modifier onlyBorrower() {
        require(msg.sender == address(borrower));
        _;
    }


    /* ========== EVENTS ========== */

    // TODO

    /* ========== VIEW FUNCTIONS ========== */

    function token() external view returns (address) {
        return address(underlyingToken);
    }

    // TODO: move to lens

    // borrower status functions
    function borrowerTotalAsset() external returns (uint256) {
        return ICreditBorrower(borrower).totalBalance();
    }

    function borrowerFreeAsset() external returns (uint256) {
        return ICreditBorrower(borrower).freeBalance();
    }

    // core view functions
    function totalCredit() public view returns (uint256) {
        return IComptroller(comptroller).creditLimits(address(this), address(ctoken));
    }

    function borrowBalanceStored() public view returns (uint256) {
        return ICToken(ctoken).borrowBalanceStored(address(this));
    }

    function borrowBalanceCurrent() public returns (uint256) {
        return ICToken(ctoken).borrowBalanceCurrent(address(this));
    }

    function previewBorrowRatePerBlock(uint256 _amount, bool _repay) external view returns (uint256) {
        return ICToken(ctoken).estimateBorrowRatePerBlockAfterChange(_amount, _repay);
    }


    // useful functions
    function creditStatusStored() public view returns (uint256, uint256) {
        return _creditStatus(totalCredit(), borrowBalanceStored());
    }

    function creditLeftStored() public view returns (uint256) {
        (uint256 creditLeft, uint256 shortfall) = creditStatusStored();
        return creditLeft;
    }

    function shortfallStored() public view returns (uint256) {
        (uint256 creditLeft, uint256 shortfall) = creditStatusStored();
        return shortfall;
    }

    function creditStatusCurrent() public returns (uint256, uint256) {
        return _creditStatus(totalCredit(), borrowBalanceCurrent());
    }

    function creditLeftCurrent() public returns (uint256) {
        (uint256 creditLeft, uint256 shortfall) = creditStatusCurrent();
        return creditLeft;
    }

    function shortfallCurrent() public returns (uint256) {
        (uint256 creditLeft, uint256 shortfall) = creditStatusCurrent();
        return shortfall;
    }

    function _creditStatus(uint256 creditAmount, uint256 borrowAmount) internal pure returns (uint256, uint256) {
        uint256 creditLeft = 0;
        uint256 shortfall = 0;
        if (creditAmount >= borrowAmount) {
            creditLeft = creditAmount - borrowAmount;
        } else {
            shortfall = borrowAmount - creditAmount;
        }
        return (creditLeft, shortfall);
    }
}
