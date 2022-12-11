## [M-5] fillorder()とexercise()はコントラクトに送られた資産を永遠にロックする可能性がある脆弱性

### ■ カテゴリー

ERC20

### ■ 条件

送金するETHの額を0に設定して、`fillOrder()` と `exercise()` を呼び出した場合

### ■ ハッキングの詳細

`fillOrder()` と `exercise()` には Ether を送る必要があるコードパスがあり (例: WETH を基本資産として使用、または行使価格の提供)、したがってこれら 2 つの関数には `payable` 修飾子が設定されています。しかし、これらの関数内にはEtherを必要としないコードパスが存在します。ETHを必要としないコードパスを使用した場合、関数に渡されたイーサは永遠にコントラクトに固定され、送信者はその見返りとして何も追加で得ることはありません。

```sol
ERC20(order.baseAsset).safeTransferFrom(order.maker, msg.sender, order.premium);
```

```sol
ERC20(order.baseAsset).safeTransferFrom(msg.sender, order.maker, order.premium);
```

```sol
ERC20(order.baseAsset).safeTransferFrom(msg.sender, address(this), order.strike);
```

### ■ 修正方法

上記メソッドで、トークンを転送するロジックを行う前に、送金するETHの金額が0であることを確認するロジックを入れる。

```sol
require(0 == msg.value)
ERC20(order.baseAsset).safeTransferFrom(order.maker, msg.sender, order.premium);
```