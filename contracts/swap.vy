# @version ^0.3.0

SUSHIROUTER: constant(address) = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F
CRV_ETH_PRICE_AGGRIGATOR: constant(address) = 0x8a12Be339B0cD1829b91Adc01977caa5E9ac121e
CRV: constant(address) = 0xD533a949740bb3306d119CC777fa900bA034cd52
WETH: constant(address) = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
DENOMINATOR: constant(uint256) = 10000
APPROVE_MID: constant(Bytes[4]) = method_id("approve(address,uint256)")
TRANSFERFROM_MID: constant(Bytes[4]) = method_id("transferFrom(address,address,uint256)")
SWAP_MID: constant(Bytes[4]) = method_id("swapExactTokensForTokens(uint256,uint256,address[],address,uint256)")

interface Aggregator:
    def latestAnswer() -> int256: view

# interface ERC20:
#     def balanceOf(_to: address) -> uint256: view

owner: public(address)
cellar: public(address)
slippage: public(uint256)

@internal
def safe_approve(_token: address, _to: address, _value: uint256):
    _response: Bytes[32] = raw_call(
        _token,
        concat(
            APPROVE_MID,
            convert(_to, bytes32),
            convert(_value, bytes32)
        ),
        max_outsize=32
    )  # dev: failed approve
    if len(_response) > 0:
        assert convert(_response, bool) # dev: failed approve

@internal
def safe_transfer_from(_token: address, _from: address, _to: address, _value: uint256):
    _response: Bytes[32] = raw_call(
        _token,
        concat(
            TRANSFERFROM_MID,
            convert(_from, bytes32),
            convert(_to, bytes32),
            convert(_value, bytes32)
        ),
        max_outsize=32
    )  # dev: failed transfer from
    if len(_response) > 0:
        assert convert(_response, bool) # dev: failed transfer from

@internal
def _token2Token2(fromToken: address, toToken: address, tokens2Trade: uint256, receiver: address, deadline: uint256) -> uint256:
    self.safe_approve(fromToken, SUSHIROUTER, tokens2Trade)
    _response: Bytes[128] = raw_call(
        SUSHIROUTER,
        concat(
            SWAP_MID,
            convert(tokens2Trade, bytes32),
            convert(0, bytes32),
            convert(160, bytes32),
            convert(receiver, bytes32),
            convert(deadline, bytes32),
            convert(2, bytes32),
            convert(fromToken, bytes32),
            convert(toToken, bytes32)
        ),
        max_outsize=128
    )
    tokenBought: uint256 = convert(slice(_response, 96, 32), uint256)
    assert tokenBought > 0, "Error Swapping Token 2"
    return tokenBought

@external
def __init__(_cellar: address):
    self.owner = msg.sender
    self.cellar = _cellar
    self.slippage = 500

@external
def swap(amount: uint256) -> uint256:
    _cellar: address = self.cellar
    assert msg.sender == _cellar
    self.safe_transfer_from(CRV, _cellar, self, amount)
    ret: uint256 = self._token2Token2(CRV, WETH, amount, _cellar, block.timestamp)
    price: uint256 = convert(Aggregator(CRV_ETH_PRICE_AGGRIGATOR).latestAnswer(), uint256)
    assert ret * 10 ** 18 / amount >= price * (DENOMINATOR - self.slippage) / DENOMINATOR
    return ret

@external
def setSlippage(_slippage: uint256):
    assert msg.sender == self.owner
    assert _slippage <= 10000
    self.slippage = _slippage

@external
def setCellar(_cellar: address):
    assert msg.sender == self.owner
    assert _cellar not in [ZERO_ADDRESS, self]
    self.cellar = _cellar
