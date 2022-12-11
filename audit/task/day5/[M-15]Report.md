## [M-15] ゼロストライクコールオプションはシステム手数料の支払いを回避することができる脆弱性

### ■ カテゴリー

ERC20

### ■ 条件

オーダーにセットされる`order.strike`の値が0または0に限りなく近い値にセットされた場合。

### ■ ハッキングの詳細

ゼロまたはゼロに近い権利行使価格のコールは、一般的なデリバティブの一種です。このようなデリバティブでは、手数料が権利行使価格の何分の一かであるため、システムは手数料を受け取ることができません。  

また、OTMのコールオプションの場合、オプションそのものはほとんど価値がないのに、権利行使価格が大きくなるため、手数料が大きくなってしまうという問題があります。例えば、1kのETH BAYCコールはあまり価値がありませんが、それを正当化するものは何もないのに、関連する手数料は通常の手数料の10倍、すなわちかなりのものになります。  

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

### ■ 修正方法

feeは、簡単に操作できないオプション価値であり、システムの取引量に正確に対応するため、オプションプレミアムと連動させるようにして簡単に操作できないようにする。