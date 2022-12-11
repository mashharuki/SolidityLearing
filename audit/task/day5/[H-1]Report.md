## [H-1] 取引に関する手数料が、putが実行されたときではなく、期限切れになったときに差し引かれる脆弱性

### ■ カテゴリー

ERC20

### ■ 条件

`order.isCall()` と `isExercised()` の値が `false`の時に発生する.

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
- putの`exercise()`し、`order.strike`分のトークンを移行した後に再度`feeAmount`を計算するようにする。具体的には下記内容を`PuttyV2.sol`451行目以降に追加

```sol
uint256 feeAmount = 0;
if (fee > 0) {
    feeAmount = (order.strike * fee) / 1000;
    ERC20(order.baseAsset).safeTransfer(owner(), feeAmount);
}
ERC20(order.baseAsset).safeTransfer(msg.sender, order.strike - feeAmount);
```

#### 修正前のコード

1箇所目

```sol
// transfer strike from putty to exerciser
ERC20(order.baseAsset).safeTransfer(msg.sender, order.strike);
```

2箇所目

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

        return;
    }
```

#### 修正後のコード

1箇所目

```sol
// transfer strike from putty to exerciser
uint256 feeAmount = 0;
if (fee > 0) {
    feeAmount = (order.strike * fee) / 1000;
    ERC20(order.baseAsset).safeTransfer(owner(), feeAmount);
}
ERC20(order.baseAsset).safeTransfer(msg.sender, order.strike - feeAmount);
```

2箇所目

```sol
    // transfer strike to owner if put is expired or call is exercised
    if ((order.isCall && isExercised) || (!order.isCall && !isExercised)) {
        // send the fee to the admin/DAO if fee is greater than 0%
        uint256 feeAmount = 0;
        (fee > 0 && order.isCall && isExercised)
            feeAmount = (order.strike * fee) / 1000;
            ERC20(order.baseAsset).safeTransfer(owner(), feeAmount);
        }

        ERC20(order.baseAsset).safeTransfer(msg.sender, order.strike - feeAmount);

        return;
    }
```