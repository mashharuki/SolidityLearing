## [M-２] 無制限ループにより、exercise()とdrawal()のメソッドの実行が失敗しDoSが発生する可能性がある脆弱性

### ■ カテゴリー

DoS

### ■ 条件

`assets.length`と`floorTokens.length`の数がとても大きい場合

### ■ ハッキングの詳細

注文で転送されるトークンの数に制限はなく、ガスの必要量も変わることがあるため（特に注文の期間は27年間）、時間T1に満たされた注文は時間T2には行使/引き出しができないかもしれないし、資産が転送中に多くのガスを使用する場合（例えばaTokensやcTokens）、提供された資産では行使できないかもしれない。オプションの買い手はプレミアムを支払っているのに、借りているアセットを手に入れることができないことになる。

```sol
function _transferERC20sOut(ERC20Asset[] memory assets) internal {
    for (uint256 i = 0; i < assets.length; i++) {
        ERC20(assets[i].token).safeTransfer(msg.sender, assets[i].tokenAmount);
    }
}
```

```sol
function _transferERC721sOut(ERC721Asset[] memory assets) internal {
    for (uint256 i = 0; i < assets.length; i++) {
        ERC721(assets[i].token).safeTransferFrom(address(this), msg.sender, assets[i].tokenId);
    }
}
```

```sol
function _transferFloorsOut(address[] memory floorTokens, uint256[] memory floorTokenIds) internal {
    for (uint256 i = 0; i < floorTokens.length; i++) {
        ERC721(floorTokens[i]).safeTransferFrom(address(this), msg.sender, floorTokenIds[i]);
    }
}
```

### ■ 修正方法

`assets.length`と`floorTokens.length`に設定できる上限値を設置すること。また、その上限値を超えていないかチェックするロジックを入れること。  

まず、上限値として定数を定義する。

```sol
const UPPER_TOKENS =  50;
```

そしてコントラクト内でチェックするロジックを加える。

```sol
function _transferFloorsOut(address[] memory floorTokens, uint256[] memory floorTokenIds) internal {
    // ここにチェックするロジックを加える
    require(floorTokens.length <= UPPER_TOKENS, "floorTokens.length is too much!")

    for (uint256 i = 0; i < floorTokens.length; i++) {
        ERC721(floorTokens[i]).safeTransferFrom(address(this), msg.sender, floorTokenIds[i]);
    }
}
```