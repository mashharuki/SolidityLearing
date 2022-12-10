## [M-5] 借り手がcloseLoanではなくrepayAndCloseLoanを呼び出すと資金を失う脆弱性

### ■ カテゴリー

ERC20

### ■ 条件

貸し手と呼び出し元のアドレスが同じ場合に`repayAndCloseLoan`メソッドを読んだ場合

### ■ ハッキングの詳細

```sol
ERC20(loan.loanAssetContractAddress).safeTransferFrom(msg.sender, lender, interest + loan.loanAmount);
```

`repayAndCloseLoan` 関数は、融資の貸し手がいない場合（lend と一致する）、元に戻りません。ユーザーはこの場合`closeLoan`を使うべきですが、ユーザーは資金を失う可能性があります。  

`ERC20(loan.loanAssetContractAddress).safeTransferFrom(msg.sender, lender, interest + loan.loanAmount) `呼び出しを実行します。interest はタイムスタンプ 0 から蓄積された高い値、loan.loanAmount は createLoan で設定した当初希望の最小ローン額 minLoanAmount になります。ユーザーが契約を承認した場合、これらの資金は失われます（例えば、別のローンのために）。

### ■ 修正方法

`loan.lastAccumulatedTimestamp`の値が0以上であることをチェックする一文を加える。

```sol
require(loan.lastAccumulatedTimestamp > 0, "loan was never matched by a lender. use closeLoan instead");
```