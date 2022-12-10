## [M-2] トークンの転送に掛かる手数料を制御していない脆弱性

### 作成者

sho, mashharuki

### ■ カテゴリー

ミドルリスク

### ■ 条件

fee on transferをサポートするトークンアドレスを使ってlend()メソッドを呼び出した場合に、`NFTLoanFacilitator.`に設定されているfeeよりもトークンに設定されているfeeの方が大きい場合。

### ■ ハッキングの詳細

```sol
    ERC20(loanAssetContractAddress).safeTransferFrom(msg.sender, address(this), amount);
    uint256 facilitatorTake = amount * originationFeeRate / SCALAR;
    ERC20(loanAssetContractAddress).safeTransfer(
        IERC721(borrowTicketContract).ownerOf(loanId),
        amount - facilitatorTake
    );
```

借り手は任意のアセットトークンを指定できるので、fee on transferをサポートするトークンでローンが作成される可能性があります。もし、fee on transfer のアセットトークンが選択された場合、プロトコルは最初の lend() 呼び出しで失敗するポイントを含んでいます。

### ■ 修正方法

originationFeeを計算した後、トークンに設定されているfeeOnTransfer以上の値になっていることをチェックするようにする。