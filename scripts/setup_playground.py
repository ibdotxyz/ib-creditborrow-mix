from brownie import (
    accounts,
    config,
    CreditOfficer,
    CreditBorrower,
    Contract,
    interface,
    network,
)

i_dai = "0x8e595470Ed749b85C6F7669de83EAe304C2ec68F"


def main():
    comptroller = Contract.from_abi(
        name="Comptroller",
        address=config["networks"][network.show_active()]["comptroller"],
        abi=interface.Comptroller.abi,
    )
    ib_admin = accounts.at(comptroller.admin(), force=True)

    # deploy a new credit officer, this will be deployed by Iron Bank
    credit_officer = CreditOfficer.deploy(
        ib_admin, comptroller, i_dai, {"from": ib_admin}
    )

    # grant 1M USDC credit to the officer
    comptroller._setCreditLimit(
        credit_officer, i_dai, 1_000_000 * 1e18, {"from": ib_admin}
    )
