## [M-1] プットオプションの手数料が無料である脆弱性

### ■ カテゴリー

ERC20

### ■ 条件

プット・オプションは手数料が無料で設定されているため。

### ■ ハッキングの詳細

しかし、現在のプロトコルの実装では、`exercise()`されたプット・オプションの手数料を差し引くことができない状態となっている。

```sol
// transfer strike to owner if put is expired or call is exercised
if ((order.isCall && isExercised) || (!order.isCall && !isExercised)) {
    // send the fee to the admin/DAO if fee is greater than 0%
    uint256 feeAmount = 0;
    if (fee > 0) {
        feeAmount = (order.strike * fee) / 1000;
        ERC20(order.baseAsset).safeTransfer(owner(), feeAmount); // @audit DoS due to reverting erc20 token transfer (weird erc20 tokens, blacklisted or paused owner; erc777 hook on owner receiver side can prevent transfer hence reverting and preventing withdrawal) - use pull pattern @high  // @audit zero value token transfers can revert. Small strike prices and low fee can lead to rounding down to 0 - check feeAmount > 0 @high  // @audit should not take fees if renounced owner (zero address) as fees can not be withdrawn @medium
    }
    ERC20(order.baseAsset).safeTransfer(msg.sender, order.strike - feeAmount); // @audit fee should not be paid if strike is simply returned to short owner for expired put @high
    return;
}
```

```sol
// transfer strike from putty to exerciser
ERC20(order.baseAsset).safeTransfer(msg.sender, order.strike);
```

### ■ 修正方法

`exercise()`されたプットオプションに対しても手数料を課すような仕組みに変更すること。