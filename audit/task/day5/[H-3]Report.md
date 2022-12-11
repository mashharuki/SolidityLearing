## [H-3] 空でないfloorでshort call  オーダーを作成すると、オプションのexerciseやwithdrawが不可能になる脆弱性

### ■ カテゴリー

ERC721

### ■ 条件

- ケース 1: baseが空の `floorAssetTokenIds` 配列で権利行使を呼び出した場合。
- ケース 2: 空ではない `floorAssetTokenIds` 配列 (`orders.floorTokens`の個数と同じであること) を指定して行使を呼び出す場合。
case1では、入力された`floorAssetTokenIds`がput注文で空であることがチェックされ、彼の呼び出しはこの要件をpassしています。しかし、最終的に`_transferFloorsIn`が呼び出され、`Index out of bounds`エラーが発生します。これは`floorTokens`が空ではなく、空のfloorAssetTokenIdsと一致しないためです。

### ■ ハッキングの詳細

`floorTokens` 配列が空でない且つfloorでshort call  オーダーが作成された場合、テイカーは`exercise()`できません。また、満期後にメーカーが引出すこともできません。注文が成立した場合にも、建玉者はプレミアムを獲得することができます。もし、`floorTokens`が空でない配列が偶然含まれていた場合、買い手は行使できずにプレミアムを失い、メーカーもロックされたERC20トークンとERC721トークンを失うという、両者にとっての損失となります。

```sol
    // case 1
    // PuttyV2.sol: _transferFloorsIn called by exercise
    // The floorTokens and floorTokenIds do not match the lenghts
    // floorTokens.length is not zero, while floorTokenIds.length is zero
    ERC721(floorTokens[i]).safeTransferFrom(from, address(this), floorTokenIds[i]);
```

```sol
    // case2
    // PuttyV2.sol: exercise
    // non empty floorAssetTokenIds array is passed for put option, it will revert
    !order.isCall
        ? require(floorAssetTokenIds.length == order.floorTokens.length, "Wrong amount of floor tokenIds")
        : require(floorAssetTokenIds.length == 0, "Invalid floor tokenIds length");
```

### ■ 修正方法

`order()`が呼び出された時に、`fillOder()`メソッドの中で、`order.floorTokens`が空であることを確認するようなロジックを追記すること。

#### 修正前のコード

```sol
    // check floor asset token ids length is 0 unless the order type is call and side is long
    !order.isCall
        ? require(floorAssetTokenIds.length == order.floorTokens.length, "Wrong amount of floor tokenIds")
        : require(floorAssetTokenIds.length == 0, "Invalid floor tokenIds length");
```

#### 修正前のコード

```sol
    // check floor asset token ids length is 0 unless the order type is call and side is long
    !order.isCall
        ? require(floorAssetTokenIds.length == order.floorTokens.length, "Wrong amount of floor tokenIds")
        : require(floorAssetTokenIds.length == 0, "Invalid floor tokenIds length");
    require(order.floorTokens.length == 0, "order.floorTokens.length must be 0");
```

