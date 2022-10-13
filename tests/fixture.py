import pytest
from brownie import (
    CreditOfficer,
    CreditOfficerFactory,
    MockCreditBorrower,
    MockComptroller,
    MockCToken,
    MockToken,
    accounts,
)


@pytest.fixture
def admin():
    return accounts[0]


@pytest.fixture
def borrower():
    return accounts[1]


@pytest.fixture
def user():
    return accounts[2]


@pytest.fixture
def token(admin):
    return admin.deploy(MockToken, 10000e18)


@pytest.fixture
def comptroller(admin):
    return admin.deploy(MockComptroller)


@pytest.fixture
def ctoken(admin, token):
    ctoken = admin.deploy(MockCToken, token)
    token.transfer(ctoken, 1000e18)
    return ctoken


@pytest.fixture
def credit_officer(admin, comptroller, ctoken):
    return admin.deploy(CreditOfficer, admin, comptroller, ctoken)


@pytest.fixture
def credit_borrower(admin, borrower, token, credit_officer):
    return admin.deploy(MockCreditBorrower, borrower, token, credit_officer)


@pytest.fixture
def credit_officer_factory(admin, comptroller):
    return admin.deploy(CreditOfficerFactory, comptroller)
