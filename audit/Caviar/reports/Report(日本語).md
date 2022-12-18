# Audit report(mashhrauki)

## [H-1] There is a risk of DoS due to the lack of a maximum value that can be set for `tokenIds`, which prevents users' assets from being traded properly.

## Summary 

infinite loops may occur in `wrap()` and `unwrap()` processes because there is no upper limit on `tokenIds`.

## Vulnerability Detail 

`tokenIds.length`を利用したループ処理が何箇所か存在するが、上限値を設けていないために無限大ループが発生する可能性がある。

## Impact 

`wrap()`や`unwrap()`、`_validateTokenIds()`内で`tokenIds.length`を利用しているが、上限値を設定していないので無数のトークンを発行したNFTコントラクトがセットされた場合に無限大ループが発生しコントラクトのラップ機能やアンラップ機能が機能しなくなる可能性がある。

## Code Snippet

https://github.com/code-423n4/2022-12-caviar/blob/main/src/Pair.sol#L238   

https://github.com/code-423n4/2022-12-caviar/blob/main/src/Pair.sol#L258  

https://github.com/code-423n4/2022-12-caviar/blob/main/src/Pair.sol#L468  


## Tool used 
特になし


## Recommendation 

下記対処法を適用する。

1. 設定できるトークン数の上限値を設定する。
2. トークンペアを登録する際にNFTのトークン数が上限値に達していないことを確認する。

**■ 修正後のコード**

```solidity
uint const UPPER_TOKENS = 10000; 

SHIP.....

// *** Checks *** //

// check that wrapping is not closed
require(closeTimestamp == 0, "Wrap: closed");

// check the tokens exist in the merkle root
_validateTokenIds(tokenIds, proofs);

// check the tokens length
require(tokenIds.length >= UPPER_TOKENS, "tokens.length is too much!!")
```

https://github.com/code-423n4/2022-03-sublime-findings/issues/27

## [M-1]  Overflowが発生し、fractional tokenのpriceが適切ではなくなるリスクがある。

## Summary 

fractional tokenのpriceを算出するために`_baseTokenReserves()`を利用しているが、変数のロジックの確認が緩いため`reverts`が発生する可能性がある。

## Vulnerability Detail 

`_baseTokenReserves()`の中で、`the current base token reserves`の値を取得しているが、`ETH`の場合に値を返す際にコントラクトの残高から`msg.value`を減算して求めている。しかし、この減算の前にコントラクトの残高が`msg.value`より大きいかどうかチェックするロジックが抜けているため`reverts`が発生し、値をうまく返せない可能性がある。

## Impact

`the current base token reserves`の値を取得できなくなるので、`baseToken`がETHだった場合に適切な`msg.value`を設定していないと`buyQuote()`、`sellQuote()`、`addQuote()`、`removeQuote()`がトークンの売買がうまく機能しなくなる。

## Code Snippet

https://github.com/code-423n4/2022-12-caviar/blob/main/src/Pair.sol#L479  

## Tool used 
特になし

## Recommendation 

下記対処法を適用する。

- address(this).balance >= msg.value であるロジックを加えること。

**before**

```sol
function _baseTokenReserves() internal view returns (uint256) {
    return baseToken == address(0)
        ? address(this).balance - msg.value // subtract the msg.value if the base token is ETH
        : ERC20(baseToken).balanceOf(address(this));
}
```

**after**

```diff
function _baseTokenReserves() internal view returns (uint256) {
+   if(baseToken == address(0)) {
+       require(address(this).balance >= msg.value, "address(this).balance must be bigger than msg.value");
+   } 

    return baseToken == address(0)
        ? address(this).balance - msg.value // subtract the msg.value if the base token is ETH
        : ERC20(baseToken).balanceOf(address(this));
}
```

## [M-2] factionnalTokenAmountの最小値が設定されていないので、overflowが発生する必要がある。

## Summary 

`buy()`と`sell()`内で移転するトークンの量を算出するために、`outputAmount`か`inputAmount`の値が利用されているが、uint256の範囲で扱える値よりも小さい値が渡された時にoverflowが発生する可能性がある。

## Vulnerability Detail 

例えば、`buy()`では最終的にユーザーに渡す`fractional tokens`の値を`buyQuote()`で算出している。

```solidity
(outputAmount * 1000 * baseTokenReserves()) / ((fractionalTokenReserves() - outputAmount) * 997);
```

## Impact 

`buy()`と`sell()`で`reverts`が発生するためトークンの売買が正常に行われないことになる。

## Code Snippet

https://github.com/code-423n4/2022-12-caviar/blob/main/src/Pair.sol#L479  

## Tool used 
特になし  

## Recommendation 

## [L-1] fractional tokenを移転する際にrevertsするリスクがある。

## Summary 

`_transferFrom()`メソッドにて、fractional tokenを移転する処理が実行されることになっているが、残高チェックに不足があり`reverts`が発生するリスクがある。

## Vulnerability Detail 

fractional tokenを移転する処理が発生する`add()`、`remove()`、`buy()`、`sell()`メソッド内で、`_transferFrom()`メソッドが呼び出されているが、送信元のアドレスのfractional tokenの残高が`amount`よりも多いことを確認するチェックが不足しているので、`reverts`が発生し資金の移転がうまく動作しない可能性がある。

## Impact 

`_transferFrom()`の実行時に`reverts`が発生し、fractional tokenの移転に失敗する可能性がある。

## Code Snippet

https://github.com/code-423n4/2022-12-caviar/blob/main/src/Pair.sol#L448  

## Tool used 
特になし 

## Recommendation 

下記対処法を適用する。

- fractional tokenの残高が`amount`よりも多いことを確認するチェックするロジックを加えること

**before**

```sol
function _transferFrom(address from, address to, uint256 amount) internal returns (bool) {
    balanceOf[from] -= amount;
```

**after**

```diff
function _transferFrom(address from, address to, uint256 amount) internal returns (bool) {
+   require(balanceOf[from] > amount, "balanceOf[from]  must be bigger than amount");
    balanceOf[from] -= amount;
```

There is a risk of overflow and manipulation of the balance of the `fractional token` held by the contract.

# [L-1] There is a risk of reverts when transferring fractional tokens.

## Summary 

The `_transferFrom()` method is supposed to transfer fractional tokens, but there is a risk of `reverts` due to insufficient balance checks.

## Vulnerability Detail 

In the `add()`, `remove()`, `buy()`, and `sell()` methods where the process of transferring fractional tokens occurs, the `_transferFrom()` method is called, but there is a missing check to ensure that the fractional token balance at the source address is greater than the `amount`, which may cause `reverts` to occur and the funds transfer to not work properly.

## Impact 

Possible `reverts` during `_transferFrom()` execution, resulting in failure to transfer fractional tokens.

## Code Snippet

https://github.com/code-423n4/2022-12-caviar/blob/main/src/Pair.sol#L448  

## Tool used 
nothing

## Recommendation 

The following measures should be applied.

- Adding check logic to ensure that the balance of the fractional token is greater than the `amount`

**before**

```sol
function _transferFrom(address from, address to, uint256 amount) internal returns (bool) {
    balanceOf[from] -= amount;
```

**after**

```diff
function _transferFrom(address from, address to, uint256 amount) internal returns (bool) {
+   require(balanceOf[from] > amount, "balanceOf[from]  must be bigger than amount");
    balanceOf[from] -= amount;
```
