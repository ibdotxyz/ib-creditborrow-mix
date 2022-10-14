# Iron Bank Credit Loan Brownie Mix

This Brownie mix comes with everything you need to start developing on Iron Bank Credit Loans.

## Installation and Setup

1. [Install Brownie](https://eth-brownie.readthedocs.io/en/stable/install.html) & [Ganache-CLI](https://github.com/trufflesuite/ganache-cli), if you haven't already.

2. Sign up for [Infura](https://infura.io/) and generate an API key. Store it in the `WEB3_INFURA_PROJECT_ID` environment variable.

```bash
export WEB3_INFURA_PROJECT_ID=YourProjectID
```

- Optional Use `network-config.yaml` provided in the repo.
  NOTE: This will replace your network config globally

```bash
cp network-config.yaml ~/.brownie/
```

3. Sign up for [Etherscan](www.etherscan.io) and generate an API key. This is required for fetching source codes of the mainnet contracts we will be interacting with. Store the API key in the `ETHERSCAN_TOKEN` environment variable.

```bash
export ETHERSCAN_TOKEN=YourApiToken
```

- Optional Use `.env` file
  1. Make a copy of `.env.example`
  2. Add the values for `ETHERSCAN_TOKEN` or `OPSCAN_TOKEN` according to the network you are going to develop on.

4. Download the mix.

```bash
git clone git@github.com:ibdotxyz/ib-creditloan-mix.git
```

## Basic Use

To perform a simple credit loan in a development environment:

1. Run `scripts/setup_playground.py` to create an officer for our credit borrower and launch the console. This automatically launches Ganache on a forked mainnet.

```bash
$ brownie run scripts/setup_playground.py --network mainnet-fork --interactive
```

1. Deploy the [`CreditBorrower.sol`](contracts/CreditBorrower.sol) contract.

```python
>>> token = credit_officer.borrowToken()
>>> credit_borrower = CreditBorrower.deploy(accounts[0], token, credit_officer, {"from": accounts[0]})
Transaction sent: 0xb173db83eeee9b35abe557f963543e0579bd3e79f710ece407e763428a0aeea1
  Gas price: 0.0 gwei   Gas limit: 12000000   Nonce: 6
  CreditBorrower.constructor confirmed   Block: 15547377   Gas used: 395321 (3.29%)
  CreditBorrower deployed at: 0x9E4c14403d7d9A8A782044E86a93CAE09D7B2ac9
```

1. Set the borrower to the newly deployed contract. We must do this because we only approved borrower contract that has been reviewed.

```python
>>> credit_officer.setBorrower(credit_borrower, {"from": ib_admin})
Transaction sent: 0xe1a4b986f14d62ad7c71e3528af8fce41eb6a4560af423ecb50db23e6e5f304c
  Gas price: 0.0 gwei   Gas limit: 12000000   Nonce: 3
  CreditOfficer.setBorrower confirmed   Block: 15547378   Gas used: 43452 (0.36%)
```

1. Borrow some DAI from Iron Bank.

```python
>>> credit_borrower.borrow(100_000 * 10 ** 18, {"from": accounts[0]})
Transaction sent: 0xa24bed673ed9eb23ce1cecae261394c73cba518aeecb6aa3730f331d26111d2a
  Gas price: 0.0 gwei   Gas limit: 12000000   Nonce: 7
  CreditBorrower.borrow confirmed   Block: 15547379   Gas used: 346029 (2.88%)
```

5. Now we are ready to put our borrower into work!

```python
>>> credit_borrower.work({"from": accounts[0]})
Transaction sent: 0x7c6bdd7f0b80547ca81583de4cdca92b240a2014b4732114140ddc074fe8b7ca
  Gas price: 0.0 gwei   Gas limit: 12000000   Nonce: 8
  CreditBorrower.work confirmed   Block: 15547380   Gas used: 22115 (0.18%)
```

## Implementing Credit Loan Logic

[`contracts/CreditBorrower.sol`](contracts/CreditBorrower.sol) is where you implement your own logic for credit loans. In particular:

- Fill in a way to calculate the total balance of the asset that are able to be repaid via `CreditBorrower.totalBalance()`
- Unwind enough of your position to payback debt via `CreditBorrower.askForRepay()`
- The destination of fund should be deterministic.
- Iron Bank should be senior debt.
- Decentralized oracle should be used to evaluate assets that are not the borrowed token.
- All operations and roles will be reviewed by Iron Bank.

See the Iron Bank documentation on [Credit Limit Assessment](https://docs.ib.xyz/v/optimism/credit-limit-assessment) for more information.

## Testing

To run the tests:

```
brownie test
```

See the [Brownie documentation](https://eth-brownie.readthedocs.io/en/stable/tests-pytest-intro.html) for more detailed information on testing your project.

## Debugging Failed Transactions

Use the `--interactive` flag to open a console immediatly after each failing test:

```
brownie test --interactive
```

Within the console, transaction data is available in the [`history`](https://eth-brownie.readthedocs.io/en/stable/api-network.html#txhistory) container:

```python
>>> history
[<Transaction '0x50f41e2a3c3f44e5d57ae294a8f872f7b97de0cb79b2a4f43cf9f2b6bac61fb4'>,
 <Transaction '0xb05a87885790b579982983e7079d811c1e269b2c678d99ecb0a3a5104a666138'>]
```

Examine the [`TransactionReceipt`](https://eth-brownie.readthedocs.io/en/stable/api-network.html#transactionreceipt) for the failed test to determine what went wrong. For example, to view a traceback:

```python
>>> tx = history[-1]
>>> tx.traceback()
```

To view a tree map of how the transaction executed:

```python
>>> tx.call_trace()
```

See the [Brownie documentation](https://eth-brownie.readthedocs.io/en/stable/core-transactions.html) for more detailed information on debugging failed transactions.

## Deployment

You should write your own deployment script and verify on Etherscan. Submit the contract address to Iron Bank for review.

# Resources

- Iron Bank [Credit Limit Assessment documentation](https://docs.ib.xyz/v/optimism/credit-limit-assessment/alpha-homora-risk-assessment)
- Iron Bank [Discord channel](https://discord.gg/4HwFTcjY78)
- Brownie [Gitter channel](https://gitter.im/eth-brownie/community)
