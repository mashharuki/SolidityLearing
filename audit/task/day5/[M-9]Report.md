## [M-9] コントラクトが、手数料なしのフラッシュローンプールとして機能する脆弱性

### ■ カテゴリー

Flash Loan

### ■ 条件

ローンの作成者とテイカーが同じアドレスである場合。

### ■ ハッキングの詳細

悪意のあるユーザは、PuttyV2コントラクトを利用して、資産に手数料を支払うことなくフラッシュローンを行い、利益を得ることができます。

```sol
ERC20(order.baseAsset).safeTransferFrom(order.maker, msg.sender, order.premium);
```

コントラクトは、標準のERC20以外のカスタムロジックを持つコントラクトを`order.baseAssets`で参照したロングコール注文でPuttyV2.fillOrderを呼び出します。この注文では、PuttyV2のコントラクトが負っているトークンとtokenAmountにerc20Assetsも指定します（erc721Assetsと同様）。
実行するメソッドが上記のコードであるとき、カスタムロジックは、コントラクトアドレス `order.baseAsset` で実行することができます。
その後、悪意のある契約は、ショートコールのポジションを行使するために、行使を呼び出します。このコールにより、`_transferERC20sOut`、`_transferERC721sOut`のロジックが実行され、注文で指定された資産が悪意のあるコントラクトに移管されます。
この契約は、その資産を他のプラットフォームで利益を上げるために使用します。その後、上記のコード実行が継続される。
`fillOrder()`が終了すると、契約は実行を終了するために`_transferERC20sIn`, `_transferERC721sIn`で論理を実行することによって、PuttyV2に十分な資産を転送することができる。

### ■ 修正方法

`exercise()`メソッド内で、`order.baseAssets`トークンを移転せずに、移転の記録にはmapping変数を利用して送信先のアドレス情報を管理するようにすること。  

その上で`redeem`という`external`修飾子をつけたメソッドを作成し、その中で`transfer`を実行すること。

```sol
mapping(uint => address) public loanOwners;
```

```sol
function redeem(Order order) external {
    // transfer
    ERC20(order.baseAsset).safeTransferFrom(order.maker, msg.sender, order.premium);
}
```
