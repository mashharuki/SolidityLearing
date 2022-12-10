## [M-1] 攻撃者がローンを貸した場合、貸した人が買い取れないようなDoSを発生させることができる脆弱性

### ■ カテゴリー

DoS

### ■ 条件

`lend()`メソッド内で、`loanAssetContractAddress`トークンを`currentLoanOwner`に移転してしまっていること。

### ■ ハッキングの詳細

```sol
    ERC20(loanAssetContractAddress).safeTransfer(
        currentLoanOwner,
        accumulatedInterest + previousLoanAmount
    );
```

攻撃者（貸し手）がローンを貸した場合、貸し手が買い取ろうとすると、攻撃者は常に取引を戻すことができ、誰でも攻撃者のローンを買い取ることができないようにすることができます。   

攻撃者は `_callTokensReceived` で `loanInfoStruct(uint256 loanId)` を呼び出し、`loanInfo` の値が変更されているかどうかをチェックして、元に戻すかどうかを決定することができます。

### ■ 修正方法

`lend()`メソッド内で、`loanAssetContractAddress`トークンを`currentLoanOwner`に移転せずに、移転の記録にはmapping変数を利用して送信先のアドレス情報を管理するようにすること。  

その上で`redeem`という`external`修飾子をつけたメソッドを作成し、その中で`transfer`を実行すること。

```sol
mapping(uint => address) public loanOwners;
```

```sol
function redeem(uint loanId, uint accumulatedInterest, uint previousLoanAmount) external {
    // transfer
    ERC20(loanAssetContractAddress).safeTransfer(
        loanOwner[loanId],
        accumulatedInterest + previousLoanAmount
    );
}
```