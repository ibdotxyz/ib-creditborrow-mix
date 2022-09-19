// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./CreditOfficer.sol";

contract CreditOfficerFactory is Ownable {
    address public immutable comptroller;
    address[] public creditOfficers;

    event CreditOfficerCreated(address creditOfficer);

    constructor(address _comptroller) {
        comptroller = _comptroller;
    }

    function create(address _ctoken) external onlyOwner returns (address) {
        CreditOfficer creditOfficer = new CreditOfficer(
            owner(),
            comptroller,
            _ctoken
        );
        creditOfficers.push(address(creditOfficer));
        emit CreditOfficerCreated(address(creditOfficer));
        return address(creditOfficer);
    }

    function getAllCreditOfficers() external view returns (address[] memory) {
        return creditOfficers;
    }
}
