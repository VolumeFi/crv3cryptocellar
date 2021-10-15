#!/usr/bin/python3

import pytest, time

from eth_abi import encode_abi

def test_deposit_withdraw_underlying(USDT, WBTC, WETH, accounts, SwapRouter, Contractcrv3cryptocellar, Contractswap, Contract):
    USDT_amount = 6000 * 10 ** 6
    SwapRouter.exactOutputSingle([WETH, USDT, 3000, accounts[0], 2 ** 256 - 1, USDT_amount, 6 * 10 ** 18, 0], {"from": accounts[0], "value": 6 * 10 ** 18})
    USDT.approve(Contractcrv3cryptocellar, USDT_amount, {"from": accounts[0]})
    print(USDT.balanceOf(accounts[0]))
    Contractcrv3cryptocellar.deposit_underlying([USDT_amount, 0, 0], {"from": accounts[0]})
    SwapRouter.exactOutputSingle([WETH, USDT, 3000, accounts[0], 2 ** 256 - 1, USDT_amount, 6 * 10 ** 18, 0], {"from": accounts[0], "value": 6 * 10 ** 18})
    USDT.approve(Contractcrv3cryptocellar, USDT_amount, {"from": accounts[0]})
    print(USDT.balanceOf(accounts[0]))
    Contractcrv3cryptocellar.deposit_underlying([USDT_amount, 0, 0], {"from": accounts[0]})
    SwapRouter.exactOutputSingle([WETH, USDT, 3000, accounts[0], 2 ** 256 - 1, USDT_amount, 6 * 10 ** 18, 0], {"from": accounts[0], "value": 6 * 10 ** 18})
    USDT.approve(Contractcrv3cryptocellar, USDT_amount, {"from": accounts[0]})
    print(USDT.balanceOf(accounts[0]))
    Contractcrv3cryptocellar.deposit_underlying([USDT_amount, 0, 0], {"from": accounts[0]})
    bal = Contractcrv3cryptocellar.balanceOf(accounts[0])
    print(bal)
    Contractcrv3cryptocellar.withdraw_underlying(0, bal)
    print(USDT.balanceOf(accounts[0]))

def test_deposit_withdraw(USDT, WBTC, WETH, accounts, SwapRouter, Contractcrv3cryptocellar, Contractswap, Crv3cryptoPool, Crv3cryptoLP, Contract):
    WETH_amount = 2 * 10 ** 18
    WETH.deposit({"from": accounts[0], "value": WETH_amount})
    WETH.approve(Crv3cryptoPool, WETH_amount, {"from": accounts[0]})
    Crv3cryptoPool.add_liquidity([0, 0, WETH_amount], 0, {"from": accounts[0]})
    amount = Crv3cryptoLP.balanceOf(accounts[0])
    Crv3cryptoLP.approve(Contractcrv3cryptocellar, amount, {"from": accounts[0]})
    Contractcrv3cryptocellar.deposit(amount, {"from": accounts[0]})
    WETH.deposit({"from": accounts[0], "value": WETH_amount})
    WETH.approve(Crv3cryptoPool, WETH_amount, {"from": accounts[0]})
    Crv3cryptoPool.add_liquidity([0, 0, WETH_amount], 0, {"from": accounts[0]})
    amount = Crv3cryptoLP.balanceOf(accounts[0])
    Crv3cryptoLP.approve(Contractcrv3cryptocellar, amount, {"from": accounts[0]})
    Contractcrv3cryptocellar.deposit(amount, {"from": accounts[0]})
    WETH.deposit({"from": accounts[0], "value": WETH_amount})
    WETH.approve(Crv3cryptoPool, WETH_amount, {"from": accounts[0]})
    Crv3cryptoPool.add_liquidity([0, 0, WETH_amount], 0, {"from": accounts[0]})
    amount = Crv3cryptoLP.balanceOf(accounts[0])
    Crv3cryptoLP.approve(Contractcrv3cryptocellar, amount, {"from": accounts[0]})
    Contractcrv3cryptocellar.deposit(amount, {"from": accounts[0]})
    bal = Contractcrv3cryptocellar.balanceOf(accounts[0])
    print(bal)
    Contractcrv3cryptocellar.withdraw_underlying(0, bal)
    print(USDT.balanceOf(accounts[0]))

def test_reinvest(USDT, WBTC, WETH, accounts, SwapRouter, Contractcrv3cryptocellar, Crv3cryptoPool, Crv3cryptoLP, Contractswap, Contract):
    USDT_amount = 6000 * 10 ** 6
    SwapRouter.exactOutputSingle([WETH, USDT, 3000, accounts[0], 2 ** 256 - 1, USDT_amount, 6 * 10 ** 18, 0], {"from": accounts[0], "value": 6 * 10 ** 18})
    USDT.approve(Contractcrv3cryptocellar, USDT_amount, {"from": accounts[0]})
    Contractcrv3cryptocellar.deposit_underlying([USDT_amount, 0, 0], {"from": accounts[0]})
    WETH_amount = 2 * 10 ** 18
    WETH.deposit({"from": accounts[0], "value": WETH_amount})
    WETH.approve(Crv3cryptoPool, WETH_amount, {"from": accounts[0]})
    Crv3cryptoPool.add_liquidity([0, 0, WETH_amount], 0, {"from": accounts[0]})
    amount = Crv3cryptoLP.balanceOf(accounts[0])
    Crv3cryptoLP.approve(Contractcrv3cryptocellar, amount, {"from": accounts[0]})
    Contractcrv3cryptocellar.deposit(amount, {"from": accounts[0]})

    bal = Contractcrv3cryptocellar.balanceOf(accounts[0])
    print(bal)
    Contractcrv3cryptocellar.reinvest({"from": accounts[0]})
    print("reinvest")
    print(Crv3cryptoLP.balanceOf(accounts[0]))
    Contractcrv3cryptocellar.withdraw(bal)
    print(Crv3cryptoLP.balanceOf(accounts[0]))
    print(USDT.balanceOf(accounts[0]))

