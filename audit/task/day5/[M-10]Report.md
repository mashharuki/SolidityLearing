## [M-10] Puttyポジショントークンは、erc721に準拠していないアドレス宛にミントされてしまう可能性がある脆弱性

### ■ カテゴリー

ERC721

### ■ 条件

NFTのミント先のアドレスにERC721準拠対応のコントラクトアドレス以外の値が設定された場合

### ■ ハッキングの詳細

Puttyはコードベース全体でERC721 safeTransferとsafeTransferFromを使用して、ERC721トークンがERC721以外の受信機に転送されないようにしています。しかし、fillOrderの最初の位置の`mint`は`_safeMint`ではなく`_mint`を使用し、Receiverに設定されたアドレスがERC721に対応しているアドレス化どうか確認していないために凍結してしまう可能性があります。

```sol
// create long/short position for maker
_mint(order.maker, uint256(orderHash));

// create opposite long/short position for taker
bytes32 oppositeOrderHash = hashOppositeOrder(order);
positionId = uint256(oppositeOrderHash);
_mint(msg.sender, positionId);
```

```sol
function _mint(address to, uint256 id) internal override {
    require(to != address(0), "INVALID_RECIPIENT");
    require(_ownerOf[id] == address(0), "ALREADY_MINTED");

    _ownerOf[id] = to;

    emit Transfer(address(0), to, id);
}
```

### ■ 修正方法

Solmateの `ERC721#_safeMint`メソッドの中に次のようなrequire文を加えること

#### 修正前のコード

```sol
function _safeMint(address to, uint256 id) internal virtual {
    _mint(to, id);
}
```

#### 修正後のコード

```sol
function _safeMint(address to, uint256 id) internal virtual {
    _mint(to, id);
    require(
        to.code.length == 0 ||
            ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
            ERC721TokenReceiver.onERC721Received.selector,
        "UNSAFE_RECIPIENT"
    );
}
```