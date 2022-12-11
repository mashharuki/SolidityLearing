## [H-1] 手数料は、プットが行使されたときではなく、期限切れになったときに差し引かれる脆弱性

### ■ カテゴリー

ERC20

### ■ 条件

if文の条件で`order.isCall` と `isExercised` が falseの時に発生する.

### ■ ハッキングの詳細

```sol
    // transfer strike to owner if put is expired or call is exercised
    if ((order.isCall && isExercised) || (!order.isCall && !isExercised)) {
        // send the fee to the admin/DAO if fee is greater than 0%
        uint256 feeAmount = 0;
        if (fee > 0) {
            feeAmount = (order.strike * fee) / 1000;
            ERC20(order.baseAsset).safeTransfer(owner(), feeAmount);
        }

        ERC20(order.baseAsset).safeTransfer(msg.sender, order.strike - feeAmount);
```

```sol
    // transfer strike from putty to exerciser
    ERC20(order.baseAsset).safeTransfer(msg.sender, order.strike);
```

### ■ 修正方法

- `PuttyV2.sol`の498行目のif文の条件を下記に変更する。

```sol
(fee > 0 && order.isCall && isExercised)
```
- プット行使、ストライク移行した後に再度feeAmountを計算するように下記内容を`PuttyV2.sol`451行目以降に追加

```sol
uint256 feeAmount = 0;
if (fee > 0) {
    feeAmount = (order.strike * fee) / 1000;
    ERC20(order.baseAsset).safeTransfer(owner(), feeAmount);
}
ERC20(order.baseAsset).safeTransfer(msg.sender, order.strike - feeAmount);
```
