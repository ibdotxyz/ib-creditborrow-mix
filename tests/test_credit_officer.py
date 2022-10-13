import brownie
import web3
from fixture import *


def test_borrow(admin, credit_officer, credit_borrower, borrower):
    credit_officer.setBorrower(credit_borrower, {"from": admin})
    credit_borrower.borrow(100e18, {"from": borrower})
    assert credit_officer.borrowBalanceStored() == 100e18


def test_borrow_with_non_borrower(credit_officer, borrower):
    with brownie.reverts("!borrower"):
        credit_officer.borrow(100e18, {"from": borrower})


def test_borrow_failed(admin, credit_officer, credit_borrower, ctoken, borrower):
    ctoken.setBorrowFailed(True)
    credit_officer.setBorrower(credit_borrower, {"from": admin})
    with brownie.reverts("borrow failed"):
        credit_borrower.borrow(100e18, {"from": borrower})


def test_borrow_shortfall(admin, credit_officer, credit_borrower, borrower, token):
    credit_officer.setBorrower(credit_borrower, {"from": admin})
    credit_borrower.borrow(100e18, {"from": borrower})
    credit_borrower.seize(token, 50e18)  # take some token off the record
    with brownie.reverts("shortfall"):
        credit_borrower.borrow(100e18, {"from": borrower})


def test_repay(admin, credit_officer, credit_borrower, borrower):
    credit_officer.setBorrower(credit_borrower, {"from": admin})
    credit_borrower.borrow(100e18, {"from": borrower})
    credit_borrower.repay(50e18, {"from": borrower})
    assert credit_officer.borrowBalanceStored() == 50e18


def test_repay_full(admin, credit_officer, credit_borrower, borrower):
    credit_officer.setBorrower(credit_borrower, {"from": admin})
    credit_borrower.borrow(100e18, {"from": borrower})
    credit_borrower.repay(web3.constants.MAX_INT, {"from": borrower})
    assert credit_officer.borrowBalanceStored() == 0


def test_repay_failed(admin, credit_officer, credit_borrower, ctoken, borrower):
    ctoken.setRepayFailed(True)
    credit_officer.setBorrower(credit_borrower, {"from": admin})
    credit_borrower.borrow(100e18, {"from": borrower})
    with brownie.reverts("repay failed"):
        credit_borrower.repay(100e18, {"from": borrower})


def test_set_borrower(admin, credit_officer, credit_borrower):
    credit_officer.setBorrower(credit_borrower, {"from": admin})
    assert credit_officer.borrower() == credit_borrower


def test_set_borrower_with_non_admin(credit_officer, credit_borrower, user):
    with brownie.reverts("Ownable: caller is not the owner"):
        credit_officer.setBorrower(credit_borrower, {"from": user})


def test_set_borrower_with_non_zero_borrow(
    admin, credit_officer, credit_borrower, borrower
):
    credit_officer.setBorrower(credit_borrower, {"from": admin})
    credit_borrower.borrow(100e18, {"from": borrower})
    with brownie.reverts("nonzero borrow balance"):
        credit_officer.setBorrower(web3.constants.ADDRESS_ZERO, {"from": admin})


def test_set_guardian(admin, credit_officer, user):
    credit_officer.setGuardian(user, {"from": admin})
    assert credit_officer.guardian() == user


def test_set_guardian_with_non_admin(credit_officer, user):
    with brownie.reverts("Ownable: caller is not the owner"):
        credit_officer.setGuardian(user, {"from": user})


def test_pause(admin, credit_officer):
    credit_officer.pause({"from": admin})
    assert credit_officer.paused() == True


def test_pause_with_guardian(admin, credit_officer, user):
    credit_officer.setGuardian(user, {"from": admin})
    credit_officer.pause({"from": user})
    assert credit_officer.paused() == True


def test_pause_with_unauthorized(credit_officer, user):
    with brownie.reverts("not authorized"):
        credit_officer.pause({"from": user})


def test_unpause(admin, credit_officer):
    credit_officer.pause({"from": admin})
    credit_officer.unpause({"from": admin})
    assert credit_officer.paused() == False


def test_unpause_with_non_admin(admin, credit_officer, user):
    credit_officer.pause({"from": admin})
    with brownie.reverts("Ownable: caller is not the owner"):
        credit_officer.unpause({"from": user})


def test_ask_for_repay(admin, credit_officer, credit_borrower, borrower):
    credit_officer.setBorrower(credit_borrower, {"from": admin})
    credit_borrower.borrow(100e18, {"from": borrower})
    credit_officer.askForRepay(50e18)
    assert credit_officer.borrowBalanceStored() == 50e18


def test_ask_for_repay_with_non_admin(
    admin, credit_officer, credit_borrower, borrower, user
):
    credit_officer.setBorrower(credit_borrower, {"from": admin})
    credit_borrower.borrow(100e18, {"from": borrower})
    with brownie.reverts("Ownable: caller is not the owner"):
        credit_officer.askForRepay(50e18, {"from": user})


def test_seize(admin, credit_officer, token):
    token.transfer(credit_officer, 100e18)
    credit_officer.seize(token, {"from": admin})


def test_seize_for_non_admin(credit_officer, token, user):
    token.transfer(credit_officer, 100e18)
    with brownie.reverts("Ownable: caller is not the owner"):
        credit_officer.seize(token, {"from": user})


def test_borrow_token(credit_officer, token):
    assert credit_officer.borrowToken() == token


def test_total_credit(admin, credit_officer, comptroller, ctoken):
    comptroller.setCreditLimit(credit_officer, ctoken, 100e18, {"from": admin})
    assert credit_officer.totalCredit() == 100e18


def test_borrow_balance(admin, credit_officer, credit_borrower, borrower):
    credit_officer.setBorrower(credit_borrower, {"from": admin})
    credit_borrower.borrow(100e18, {"from": borrower})
    assert credit_officer.borrowBalanceStored() == 100e18
    assert credit_officer.borrowBalanceCurrent.call() == 100e18


def test_credit_status(
    admin, credit_officer, credit_borrower, comptroller, ctoken, borrower
):
    comptroller.setCreditLimit(credit_officer, ctoken, 100e18, {"from": admin})
    credit_officer.setBorrower(credit_borrower, {"from": admin})
    credit_borrower.borrow(50e18, {"from": borrower})

    credit_left, shortfall = credit_officer.creditStatusStored()
    assert credit_left == 50e18
    assert shortfall == 0

    credit_left, shortfall = credit_officer.creditStatusCurrent.call()
    assert credit_left == 50e18
    assert shortfall == 0

    comptroller.setCreditLimit(credit_officer, ctoken, 20e18, {"from": admin})

    credit_left, shortfall = credit_officer.creditStatusStored()
    assert credit_left == 0
    assert shortfall == 30e18

    credit_left, shortfall = credit_officer.creditStatusCurrent.call()
    assert credit_left == 0
    assert shortfall == 30e18
