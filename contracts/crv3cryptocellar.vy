# @version ^0.3.0

event Transfer:
    _from: indexed(address)
    _to: indexed(address)
    _value: uint256

event Approval:
    _owner: indexed(address)
    _spender: indexed(address)
    _value: uint256

name: public(String[64])
symbol: public(String[32])

balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])
totalSupply: public(uint256)

CRV3CRYPTO_LP: constant(address) = 0xc4AD29ba4B3c580e6D59105FFf484999997675Ff
CRV: constant(address) = 0xD533a949740bb3306d119CC777fa900bA034cd52
CRV_MINTER: constant(address) = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0
CRV3CRYPTO_POOL: constant(address) = 0xD51a44d3FaE010294C616388b506AcdA1bfAAE46
CRV3CRYPTO_GAUGE: constant(address) = 0xDeFd8FdD20e0f34115C7018CCfb655796F6B2168
USDT: constant(address) = 0xdAC17F958D2ee523a2206206994597C13D831ec7
WBTC: constant(address) = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599
WETH: constant(address) = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
COINS: constant(address[3]) = [USDT, WBTC, WETH]

validators: public(HashMap[address, bool])
lp_balance: public(uint256)
owner: public(address)
swap: public(address)

APPROVE_MID: constant(Bytes[4]) = method_id("approve(address,uint256)")
TRANSFER_MID: constant(Bytes[4]) = method_id("transfer(address,uint256)")
TRANSFERFROM_MID: constant(Bytes[4]) = method_id("transferFrom(address,address,uint256)")
DEPOSIT_MID: constant(Bytes[4]) = method_id("deposit(address,uint256,address,uint16)")
GRD_MID: constant(Bytes[4]) = method_id("getReserveData(address)")

FEE_DOMINATOR: constant(uint256) = 10000

interface Gauge:
    def deposit(_value: uint256): nonpayable
    def withdraw(_value: uint256): nonpayable

interface CrvMinter:
    def mint(_gauge: address): nonpayable

interface CrvPool:
    def add_liquidity(amounts: uint256[3], min_mint_amount: uint256): nonpayable
    def remove_liquidity_one_coin(token_amount: uint256, i: uint256, min_amount: uint256): nonpayable

interface ERC20:
    def balanceOf(_to: address) -> uint256: view

interface Swap:
    def swap(bal: uint256) -> uint256: nonpayable

interface WrappedEth:
    def deposit(): payable
    def withdraw(amount: uint256): nonpayable

@external
def __init__(_name: String[64], _symbol: String[32]):
    self.name = _name
    self.symbol = _symbol
    self.owner = msg.sender
    self.validators[msg.sender] = True

@internal
def _mint(_to: address, _value: uint256):
    assert _to != ZERO_ADDRESS, "mint to zero address"
    self.totalSupply += _value
    self.balanceOf[_to] += _value
    log Transfer(ZERO_ADDRESS, _to, _value)

@internal
def _burn(_to: address, _value: uint256):
    assert _to != ZERO_ADDRESS, "burn from zero address"
    self.totalSupply -= _value
    self.balanceOf[_to] -= _value
    log Transfer(_to, ZERO_ADDRESS, _value)

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
def safe_transfer(_token: address, _to: address, _value: uint256):
    _response: Bytes[32] = raw_call(
        _token,
        concat(
            TRANSFER_MID,
            convert(_to, bytes32),
            convert(_value, bytes32)
        ),
        max_outsize=32
    )  # dev: failed transfer
    if len(_response) > 0:
        assert convert(_response, bool) # dev: failed transfer

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

@external
@pure
def decimals() -> uint256:
    return 18

@external
def transfer(_to : address, _value : uint256) -> bool:
    assert _to != ZERO_ADDRESS # dev: zero address
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value
    log Transfer(msg.sender, _to, _value)
    return True

@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    assert _to != ZERO_ADDRESS # dev: zero address
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    self.allowance[_from][msg.sender] -= _value
    log Transfer(_from, _to, _value)
    return True

@external
def approve(_spender : address, _value : uint256) -> bool:
    assert _value == 0 or self.allowance[msg.sender][_spender] == 0
    self.allowance[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True

@external
def increaseAllowance(_spender: address, _value: uint256) -> bool:
    allowance: uint256 = self.allowance[msg.sender][_spender]
    allowance += _value
    self.allowance[msg.sender][_spender] = allowance
    log Approval(msg.sender, _spender, allowance)
    return True

@external
def decreaseAllowance(_spender: address, _value: uint256) -> bool:
    allowance: uint256 = self.allowance[msg.sender][_spender]
    allowance -= _value
    self.allowance[msg.sender][_spender] = allowance
    log Approval(msg.sender, _spender, allowance)
    return True

@external
def deposit(amount: uint256):
    self.safe_transfer_from(CRV3CRYPTO_LP, msg.sender, self, amount)
    self.safe_approve(CRV3CRYPTO_LP, CRV3CRYPTO_GAUGE, amount)
    Gauge(CRV3CRYPTO_GAUGE).deposit(amount)
    _lp_balance: uint256 = self.lp_balance
    if _lp_balance == 0:
        self._mint(msg.sender, amount)
    else:
        self._mint(msg.sender, amount * self.totalSupply / _lp_balance)
    self.lp_balance = _lp_balance + amount

@external
@payable
def deposit_underlying(_amounts: uint256[3]):
    amounts: uint256[3] = _amounts
    coins: address[3] = COINS
    for i in range(3):
        if amounts[i] > 0:
            self.safe_transfer_from(coins[i], msg.sender, self, amounts[i])
            self.safe_approve(coins[i], CRV3CRYPTO_POOL, amounts[i])
    if msg.value > 0:
        WrappedEth(WETH).deposit(value=msg.value)
        amounts[2] += msg.value
    amount: uint256 = ERC20(CRV3CRYPTO_LP).balanceOf(self)
    CrvPool(CRV3CRYPTO_POOL).add_liquidity(amounts, 0)
    amount = ERC20(CRV3CRYPTO_LP).balanceOf(self) - amount
    self.safe_approve(CRV3CRYPTO_LP, CRV3CRYPTO_GAUGE, amount)
    Gauge(CRV3CRYPTO_GAUGE).deposit(amount)
    _lp_balance: uint256 = self.lp_balance
    if _lp_balance == 0:
        self._mint(msg.sender, amount)
    else:
        self._mint(msg.sender, amount * self.totalSupply / _lp_balance)
    self.lp_balance = _lp_balance + amount

@external
def withdraw(amount: uint256):
    _amount: uint256 = self.balanceOf[msg.sender]
    if amount < _amount:
        _amount = amount
    _lp_balance: uint256 = self.lp_balance
    lp_amount: uint256 = _amount * _lp_balance / self.totalSupply
    Gauge(CRV3CRYPTO_GAUGE).withdraw(lp_amount)
    self.safe_transfer(CRV3CRYPTO_LP, msg.sender, lp_amount)
    self._burn(msg.sender, _amount)
    self.lp_balance = _lp_balance - lp_amount

@external
@nonreentrant('lock')
def withdraw_underlying(tokenIndex: uint256, amount: uint256):
    assert tokenIndex <= 3, "Wrong index"
    _amount: uint256 = self.balanceOf[msg.sender]
    if amount < _amount:
        _amount = amount
    _lp_balance: uint256 = self.lp_balance
    lp_amount: uint256 = _amount * _lp_balance / self.totalSupply
    Gauge(CRV3CRYPTO_GAUGE).withdraw(lp_amount)
    self.safe_approve(CRV3CRYPTO_LP, CRV3CRYPTO_POOL, lp_amount)
    underlying_bal: uint256 = 0
    if tokenIndex < 3:
        coins: address[3] = COINS
        underlying_bal = ERC20(coins[tokenIndex]).balanceOf(self)
        CrvPool(CRV3CRYPTO_POOL).remove_liquidity_one_coin(lp_amount, tokenIndex, 0)
        underlying_bal = ERC20(coins[tokenIndex]).balanceOf(self) - underlying_bal
        self.safe_transfer(coins[tokenIndex], msg.sender, underlying_bal)
    else:
        underlying_bal = ERC20(WETH).balanceOf(self)
        CrvPool(CRV3CRYPTO_POOL).remove_liquidity_one_coin(lp_amount, 2, 0)
        underlying_bal = ERC20(WETH).balanceOf(self) - underlying_bal
        WrappedEth(WETH).withdraw(underlying_bal)
        send(msg.sender, underlying_bal)
    self._burn(msg.sender, _amount)
    self.lp_balance = _lp_balance - lp_amount

@external
def reinvest():
    assert self.validators[msg.sender], "Not Validator"
    CrvMinter(CRV_MINTER).mint(CRV3CRYPTO_GAUGE)
    amount: uint256 = ERC20(CRV).balanceOf(self)
    if amount > 0:
        self.safe_approve(CRV, self.swap, amount)
        amount = Swap(self.swap).swap(amount)
        self.safe_approve(WETH, CRV3CRYPTO_POOL, amount)
        CrvPool(CRV3CRYPTO_POOL).add_liquidity([0, 0, amount], 0)
        amount = ERC20(CRV3CRYPTO_LP).balanceOf(self)
        self.safe_approve(CRV3CRYPTO_LP, CRV3CRYPTO_GAUGE, amount)
        Gauge(CRV3CRYPTO_GAUGE).deposit(amount)
        self.lp_balance += amount

@external
def setSwap(_swap: address):
    assert msg.sender == self.owner
    self.swap = _swap

@external
def transferOwnership(_owner: address):
    assert msg.sender == self.owner and _owner != ZERO_ADDRESS
    self.owner = _owner

@external
def setValidator(_validator: address, _value: bool):
    assert msg.sender == self.owner
    self.validators[_validator] = _value
