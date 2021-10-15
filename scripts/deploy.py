from brownie import crv3cryptocellar, swap, accounts

def main():
    acct = accounts.load("deployer_account")
    token_name = "Crv3Crypto cellar"
    token_symbol = "sommCrv3Crypto"
    cellar_address = crv3cryptocellar.deploy(token_name, token_symbol, {'from': acct})
    swap_address = swap.deploy(cellar_address, {'from': acct})
    cellar_address.setSwap(swap_address, {'from': acct})