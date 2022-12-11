## [H-2] acceptcounteroffer()は両方の注文が満たされる結果になることがある脆弱性

### ■ カテゴリー

FrontRunning

### ■ 条件

すでに`order`が失敗している時に、`cancel()`メソッドを呼び出すこと。

### ■ ハッキングの詳細

ユーザがカウンターオファーを受け入れようとする場合、acceptCounterOffer() 関数を、キャンセルされる originalOrder と、満たされるべき新しい order の両方とともに呼び出します。攻撃者(または同時にfillOrder()を呼び出した他のユーザ)は、acceptCounterOffer()がキャンセルする前にoriginalOrderを埋めることが可能です。

その結果、originalOrder と order の両方が満たされることになります。acceptCounterOffer() の msg.sender は、必要なトークン転送が成功すると、意図したよりも 2 倍活用されます。

```sol
   function acceptCounterOffer(
        Order memory order,
        bytes calldata signature,
        Order memory originalOrder
    ) public payable returns (uint256 positionId) {
        // cancel the original order
        cancel(originalOrder);
        // accept the counter offer
        uint256[] memory floorAssetTokenIds = new uint256[](0);
        positionId = fillOrder(order, signature, floorAssetTokenIds);
    }
```

```sol
    function cancel(Order memory order) public {
        require(msg.sender == order.maker, "Not your order");
        bytes32 orderHash = hashOrder(order);
        // mark the order as cancelled
        cancelledOrders[orderHash] = true;
        emit CancelledOrder(orderHash, order);
    }
```

### ■ 修正方法

すでに`order`が失敗している時は、`cancel()`メソッドが失敗するような条件を加えること

```sol
equire(_ownerOf[uint256(orderHash)] == 0)
```