// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;


interface ICreditOfficer {

    /*****************************
     * functions for admin
     ****************************/
    function askForRepay(uint256 amount) external;


    /*****************************
     * functions for borrower
     ****************************/
    function token() external view returns (address);

    function borrow(uint256 amount) external;
    function repay(uint256 amount) external;


    // TODO: move to Lens
    function previewBorrowRatePerBlock(uint256 amount, bool repay) external view returns (uint256);

    function totalCredit() external view returns (uint256);
    function borrowBalanceStored() external view returns (uint256);
    function borrowBalanceCurrent() external returns (uint256);

    function creditStatusStored() external view returns (uint256 creditLeft, uint256 shortfall);
    function creditLeftStored() external view returns (uint256);
    function shortfallStored() external view returns (uint256);

    function creditStatusCurrent() external returns (uint256 creditLeft, uint256 shortfall);
    function creditLeftCurrent() external returns (uint256);
    function shortfallCurrent() external returns (uint256);
}
