# CRV3CRYPTO(Curve LP) Cellar

## Testing and Development on testnet

### Dependencies
* [nodejs](https://nodejs.org/en/download/) - >=v8, tested with version v14.15.4
* [python3](https://www.python.org/downloads/release/python-368/) from version 3.6 to 3.8, python3-dev
* [brownie](https://github.com/iamdefinitelyahuman/brownie) - tested with version [1.14.6](https://github.com/eth-brownie/brownie/releases/tag/v1.14.6)
* ganache-cli

Run Ganache-cli mainnet-fork environment

```bash
ganache-cli --fork https://mainnet.infura.io/v3/#{YOUR_INFURA_KEY} -p 7545
```

Add local network setting to brownie

```bash
brownie networks add Development local host=http://127.0.0.1 accounts=10 evm_version=istanbul fork=mainnet port=7545 mnemonic=brownie cmd=ganache-cli timeout=300
```

Deploy on local ganache-cli network

```bash
brownie run scripts/deploy.py --network local
```

Deploy on mainnet

```bash
brownie run scripts/deploy.py --network mainnet
```

### Running the Tests
```bash
brownie test --network local
```



Contracts

- crv3cryptocellar - Main contract
- swap - Periphery contract to swap CRV reward into ETH



## External functions

| Function Name | Parameters | Note | Description |
| --- | --- | --- | --- |
|transfer|address recipient, uint256 amount|||
|approve|address spender, uint256 amount|||
|transferFrom|address sender,address recipient,uint256 amount|||
|increaseAllowance|addresss spender, uint256 value||Increase allowance|
|decreaseAllowance|address spender, uint256 value||Decrease allowance|
|deposit|uint256 amount||Deposit crv3crypto curveLP token|
|deposit_underlying|uint256[3] amounts|payable|Deposit USDT/WBTC/WETH, msg.value is for ETH|
|withdraw|uint256 amount||Withdraw crv3crypto curveLP token|
|withdraw_underlying|uint256 tokenIndex, uint256 amount||Withdraw underlying token<br />tokenIndexes 0-USDT, 1-WBTC, 2-WETH, 3-ETH|
|reinvest| | | Collect CRV, swap into curveLP, and reinvest |
|setSwap| address _swap | | new swap logic contract |
|setValidator|address _validator, bool value|||
|transferOwnership|address, newOwner|||
|owner||view||
|name||view||
|symbol||view||
|decimals||pure||
|totalSupply||view||
|balanceOf|address account|view||
|allowance|address owner_, address spender|view||
|swap||view|Address of the swap contract that swaps CRV into ETH|
|lp_balance||view|crv3crypto LP balance|
|validators|address|view|Validator check (bool)|
