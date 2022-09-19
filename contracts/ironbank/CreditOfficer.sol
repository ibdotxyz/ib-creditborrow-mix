// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../interfaces/ICreditOfficer.sol";
import "../../interfaces/ICreditBorrower.sol";
import "../../interfaces/IComptroller.sol";
import "../../interfaces/ICToken.sol";

contract CreditOfficer is Ownable, Pausable, ReentrancyGuard, ICreditOfficer {
    using SafeERC20 for IERC20;

    IComptroller public immutable comptroller;
    ICToken public immutable ctoken;
    IERC20 public immutable underlyingToken;

    address public guardian;
    ICreditBorrower public borrower;

    event BorrowerSet(address borrower);
    event GuardianSet(address guardian);
    event RepayRequested(uint256 amount);
    event Seize(address token, uint256 amount);

    constructor(
        address _admin,
        address _comptroller,
        address _ctoken
    ) {
        comptroller = IComptroller(_comptroller);
        ctoken = ICToken(_ctoken);
        underlyingToken = IERC20(ICToken(_ctoken).underlying());
        underlyingToken.approve(_ctoken, type(uint256).max);

        transferOwnership(_admin);
    }

    modifier onlyBorrower() {
        require(msg.sender == address(borrower), "!borrower");
        _;
    }

    /**
     * @notice Borrow from Iron Bank.
     * @param amount The amount of token to borrow.
     */
    function borrow(uint256 amount)
        external
        onlyBorrower
        nonReentrant
        whenNotPaused
    {
        ctoken.borrow(amount);
        underlyingToken.transfer(address(borrower), amount);
        require(
            borrower.totalBalance() >=
                ctoken.borrowBalanceStored(address(this)),
            "shortfall"
        );
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
        underlyingToken.transferFrom(
            address(borrower),
            address(this),
            repayAmount
        );
        ctoken.repayBorrow(amount);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @notice Set the borrower.
     */
    function setBorrower(address _borrower) external onlyOwner {
        if (address(borrower) != address(0)) {
            require(borrowBalanceCurrent() == 0, "nonzero borrow balance");
        }
        borrower = ICreditBorrower(_borrower);
        emit BorrowerSet(_borrower);
    }

    /**
     * @notice Set the guardian.
     */
    function setGuardian(address _guardian) external onlyOwner {
        guardian = _guardian;
        emit GuardianSet(_guardian);
    }

    /**
     * @notice Pause borrowing.
     */
    function pause() external {
        require(
            msg.sender == owner() || msg.sender == guardian,
            "not authorized"
        );
        _pause();
    }

    /**
     * @notice Unpause borrowing.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Ask for Repay.
     */
    function askForRepay(uint256 amount) external onlyOwner {
        borrower.askForRepay(amount);
        emit RepayRequested(amount);
    }

    /**
     * @notice Seize.
     */
    function seize(address token) external onlyOwner {
        uint256 bal = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(owner(), bal);
        emit Seize(token, bal);
    }

    /* ========== VIEW FUNCTIONS ========== */

    function borrowToken() external view returns (address) {
        return address(underlyingToken);
    }

    // borrower status functions
    function borrowerTotalAsset() external returns (uint256) {
        return ICreditBorrower(borrower).totalBalance();
    }

    function borrowerFreeAsset() external returns (uint256) {
        return ICreditBorrower(borrower).freeBalance();
    }

    // core view functions
    function totalCredit() public view returns (uint256) {
        return
            IComptroller(comptroller).creditLimits(
                address(this),
                address(ctoken)
            );
    }

    function borrowBalanceStored() public view returns (uint256) {
        return ICToken(ctoken).borrowBalanceStored(address(this));
    }

    function borrowBalanceCurrent() public returns (uint256) {
        return ICToken(ctoken).borrowBalanceCurrent(address(this));
    }

    function previewBorrowRatePerBlock(uint256 _amount, bool _repay)
        external
        view
        returns (uint256)
    {
        return
            ICToken(ctoken).estimateBorrowRatePerBlockAfterChange(
                _amount,
                _repay
            );
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

    function _creditStatus(uint256 creditAmount, uint256 borrowAmount)
        internal
        pure
        returns (uint256, uint256)
    {
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
