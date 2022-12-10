## [H-2] どのレンダーもバイアウトしようとすると、currentLoanOwnerがloanInfoを操作することができる脆弱性

### ■ カテゴリー

ハイリスク

### ■ 条件

- 攻撃者がすでに貸付を行っていること lend()の呼び出し
- そのタイミングで貸し手が買い取ろうとしていること transfer()の呼び出し

### ■ ハッキングの詳細

```sol
    ERC20(loanAssetContractAddress).safeTransfer(
        currentLoanOwner,
        accumulatedInterest + previousLoanAmount
    );
```

```sol
    ERC20(loan.loanAssetContractAddress).safeTransferFrom(
        msg.sender,
        currentLoanOwner,
        accumulatedInterest + previousLoanAmount    
    )
```

攻撃者が既に lend() を呼び出して貸し付けを行っている場合、任意の貸し手が買い取ろうとすると、攻撃者は reentrancy 攻撃によって loanInfo を操作することができます。攻撃者は、買い取りを希望する貸し手が予期しないような悪い値 (例えば、非常に長い期間や0金利) を lendInfo に設定することができます。

### ■ 修正方法

リエントランシー攻撃を防ぐために、ReentrancyGuard.solで定義されているような、修飾子をlend()メソッドにも適用すること。