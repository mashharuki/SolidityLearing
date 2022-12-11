## [M-7] 攻撃者が(cryptopunkのような)ERC721に準拠していないNFTでshortプットオプションオーダーを作成でき、ユーザーはそのオーダーを満たすことができるが、オプションをexerciseすることができない脆弱性

### ■ カテゴリー

ERC721

### ■ 条件

`baseAsset`にcryptopunkのようなERC721に準拠していないNFTコントラクトのアドレスを設定した場合

### ■ ハッキングの詳細

攻撃者は、cryptopunkを使ってショートプットオプションを作成することができます。ユーザーが注文を実行すると、`baseAsset`がコントラクトに転送されます。

しかし、cryptopunkはERC721をサポートしていないため、`safeTransferFrom`関数呼び出しが失敗し、ユーザーはオプションを`exercise()`することができなくなります。攻撃者はプレミアムを取得し、オプションの期限が切れた後に`baseAsset`を取り戻すことができます。

```sol
if (!order.isLong && !order.isCall) {
    ERC20(order.baseAsset).safeTransferFrom(order.maker, address(this), order.strike);
    return positionId;
}

```

```sol
ERC721(floorTokens[i]).safeTransferFrom(from, address(this), floorTokenIds[i]);
```

### ■ 修正方法

`baseAsset`に設定できるNFTについては、ERC721に準拠したトークンアドレスのみを使用できるようにホワイトリスト化して管理すること。
