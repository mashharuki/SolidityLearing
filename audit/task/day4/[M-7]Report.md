## [M-7] mintBorrowTicketToはonERC721Receivedメソッドを持たない契約である可能性があり、これによりBorrowTicket NFTが凍結され、ユーザーの資金が危険にさらされる可能性があります。

### ■ カテゴリー

ミドルリスク

### ■ 条件

`_mint`メソッドによりミントする先のアドレスが、IERC721に対応しているコントラクト以外である場合

### ■ ハッキングの詳細

```sol
function mint(address to, uint256 tokenId) external override loanFacilitatorOnly {
    _mint(to, tokenId);
}
```

NFTLoanFacilitator.solの102行目あたりで_mintメソッドを呼んでいるが、ここでtoのアドレスがIERC721に対応していないと適切ではないアドレスにNFTをミントしてしまうことになる。(凍結状態となる。)

### ■ 修正方法

`_mint`メソッドではなく、`_safeMint`を使うようにすること。

```sol
function mint(address to, uint256 tokenId) external override loanFacilitatorOnly {
    _safeMint(to, tokenId);
}
```