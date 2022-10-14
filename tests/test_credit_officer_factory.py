import brownie
from fixture import *


def test_create(admin, credit_officer_factory, ctoken):
    credit_officer_factory.create(ctoken, {"from": admin})
    assert len(credit_officer_factory.getAllCreditOfficers()) == 1


def test_borrow_with_non_admin(credit_officer_factory, ctoken, user):
    with brownie.reverts("Ownable: caller is not the owner"):
        credit_officer_factory.create(ctoken, {"from": user})
