# InsuranceFund depositors can be priced out & deposits can be stolen 

## コードの詳細

https://github.com/code-423n4/2022-02-hubble/blob/8c157f519bc32e552f8cc832ecc75dc381faa91e/contracts/InsuranceFund.sol#L44-L54

## 脆弱性の詳細

### 脆弱性の影響

The InsuranceFund.deposit function mints initial shares equal to the deposited amount.  
The deposit / withdraw functions also use the VUSD contract balance for the shares computation.   
(balance() = vusd.balanceOf(address(this)))

It's possible to increase the share price to very high amounts and price out smaller depositors.

`InsuranceFund.deposit`関数は、預け入れ額と同じ額の初期トークンをミントします。
入金/出金関数は、トークン価格の計算にVUSDコントラクトの残高を使用します。  
(balance() = vusd.balanceOf(address(this)))  

トークンの価格を非常に高くして、少額の預金者を排除することが可能です。

### PoC

- deposit(_amount = 1): Deposit the smallest unit of VUSD as the first depositor. Mint 1 share and set the total supply and VUSD balance to 1.
- Perform a direct transfer of 1000.0 VUSD to the InsuranceFund. The balance() is now 1000e6 + 1
- Doing any deposits of less than 1000.0 VUSD will mint zero shares: shares = _amount * _totalSupply / _pool = 1000e6 * 1 / (1000e6 + 1) = 0.
- The attacker can call withdraw(1) to burn their single share and receive the entire pool balance, making a profit. (balance() * _shares / totalSupply() = balance())

I give this a high severity as the same concept can be used to always steal the initial insurance fund deposit by frontrunning it and doing the above-mentioned steps, just sending the frontrunned deposit amount to the contract instead of the fixed 1000.0.
They can then even repeat the steps to always frontrun and steal any deposits.  

同じコンセプトで、最初の保険金の預託を前倒しで行い、上記の手順を行うことで、固定された1000.0ではなく、前倒しした預託額をコントラクトに送るだけで常に盗むことができるため、私はこれをハイリスクとしています。さらに、この手順を繰り返すことで、常にフロントランを行い、あらゆる預金を盗むことができます。

## 推奨対策

The way UniswapV2 prevents this is by requiring a minimum deposit amount and sending 1000 initial shares to the zero address to make this attack more expensive.
The same mitigation can be done here.  

UniswapV2がこれを防ぐ方法は、最低入金額を要求し、ゼロアドレスに1000トークンの初期トークンを送ることで、この攻撃に対するハードルを高くすることです。
ここでも同じような緩和が可能です。(uniswapVwPair.solの_mintのところ！！！)

## バグの原因
ゼロアドレスに初期トークンをミントしていないこと。