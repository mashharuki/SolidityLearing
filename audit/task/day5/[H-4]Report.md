## [H-4] 0 strike call オプションは、買い手からプレミアムを奪うのに使用できてしまう脆弱性

### ■ カテゴリー

Weird ERC20 Tokens

### ■ 条件

送金するトークンの送金量が0であること。

### ■ ハッキングの詳細

現在、このPuttyV2コントラクトでは権利行使価格を確認せず、無条件に`safeTransferFrom`を実行しようとしています。 
しかし、`Weird ERC20 Tokens`に準拠しているトークンでは送金額を0に設定して`transfer`することはできないので、`reverts`が発生します。

```sol
    function exercise(Order memory order, uint256[] calldata floorAssetTokenIds) public payable {
    ...
    if (order.isCall) {
        // -- exercising a call option
        // transfer strike from exerciser to putty
        // handle the case where the taker uses native ETH instead of WETH to pay the strike
        if (weth == order.baseAsset && msg.value > 0) {
            // check enough ETH was sent to cover the strike
            require(msg.value == order.strike, "Incorrect ETH amount sent");
            // convert ETH to WETH
            // we convert the strike ETH to WETH so that the logic in withdraw() works
            // - because withdraw() assumes an ERC20 interface on the base asset.
            IWETH(weth).deposit{value: msg.value}();
        } else {
            ERC20(order.baseAsset).safeTransferFrom(msg.sender, address(this), order.strike);
        }
        // transfer assets from putty to exerciser
        _transferERC20sOut(order.erc20Assets);
        _transferERC721sOut(order.erc721Assets);
        _transferFloorsOut(order.floorTokens, positionFloorAssetTokenIds[uint256(orderHash)]);
    }
```

### ■ 修正方法

送金するトークンの量が0より大きいことを確認するロジックを追記すること。

#### 修正前のコード

```sol
    } else {
        ERC20(order.baseAsset).safeTransferFrom(msg.sender, address(this), order.strike);
    }
```

#### 修正後のコード

```sol
    } else {
        if (order.strike > 0) {
            ERC20(order.baseAsset).safeTransferFrom(msg.sender, address(this), order.strike);
        }
    }
```