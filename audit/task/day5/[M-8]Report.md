## [M-8] erc721.transferfrom() と erc20.transferfrom() の間の重複は、order.erc20assets または order.baseasset が erc20 でなく erc721 になることを可能にする脆弱性。

### ■ カテゴリー

ERC20, ERC721

### ■ 条件

`baseAsset` や `erc20Assets`にセットされているコントラクトアドレス が ERC20 ではなく ERC721 アドレスとして処理されてしまった場合

### ■ ハッキングの詳細

ERC20とERC721の`transferFrom()`は両方とも同じメソッドIDを持っています。  
この影響により、`baseAsset` や `erc20Assets` が ERC20 ではなく ERC721 アドレスになる可能性があります。

これらの関数は、NFTをプロトコルに正常に転送しますが、NFTをコントラクトの外に転送することには失敗します。これは、転送用のメソッドが `ERC20.safeTransfer()` で `transfer(to, amount)` を呼び出すためで、ERC721 の有効な関数のメソッドIDと一致しないためです。

したがって、この方法で`fillOrder()`を使ってコントラクトに転送されたERC721トークンは、`exercise()`や`withdraw()`がコントラクトからトークンをうまく転送できないため、永久にその中に留まってしまうことになります。

```sol
ERC20(order.baseAsset).safeTransferFrom(order.maker, msg.sender, order.premium);
```

```sol
ERC20(token).safeTransferFrom(from, address(this), tokenAmount);
```

### ■ 修正方法

承認したERC721とERC20のトークンアドレス情報をホワイトリスト化する。またそのホワイトリストを分けて管理すること。