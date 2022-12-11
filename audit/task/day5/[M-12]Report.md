## [M-12] 権利行使価格の小さいオプションは0に切り捨てられ、資産の引き出しができなくなる可能性がある脆弱性

### ■ カテゴリー

ERC20

### ■ 条件

order.strikeとfeeがかなり小さい値にセットされている場合

### ■ ハッキングの詳細

特定のERC-20トークンは、総金額0のトークンの転送と復帰をサポートしていません。そのようなトークンを、かなり小さなオプション行使と低いプロトコル手数料率の`order.baseAsset`として使用すると、0に切り捨てられ、それらのポジションの資産の引き出しができなくなる可能性があります。

```sol
feeAmount = (order.strike * fee) / 1000;
ERC20(order.baseAsset).safeTransfer(owner(), feeAmount);
``` 

### ■ 修正方法

総金額が0より大きいことをチェックするロジックを加えること

```sol
// send the fee to the admin/DAO if fee is greater than 0%
uint256 feeAmount = 0;
if (fee > 0) {
    feeAmount = (order.strike * fee) / 1000;
    if (feeAmount > 0) {
        ERC20(order.baseAsset).safeTransfer(owner(), feeAmount);
    }
}
```