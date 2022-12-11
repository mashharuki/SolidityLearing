## [M-8] order.erc20assets または order.baseasset が erc20 でなく erc721 になる可能がある脆弱性。

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

PuttyV2コントラクト内で使用するERC721とERC20のトークンアドレス情報をホワイトリスト化して管理する。またそのホワイトリストをERC20用とERC721用に分けて管理すること。