## [H-2] どのlenderもbuyoutしようとすると、currentLoanOwnerがloanInfoを操作することができる脆弱性

### ■ カテゴリー

Reentrancy

### ■ 条件

- 攻撃者が`lend()`の呼び出し、そのタイミングで貸し手が`transfer()`の呼び出した場合

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

攻撃者が既に `lend()` を呼び出している場合、任意の貸し手が買い取ろうとすると、攻撃者は reentrancy 攻撃によって `loanInfo` を操作することができます。攻撃者は、買い取りを希望する貸し手が予期しないような悪い値 (例えば、非常に長い期間や0金利) を `lendInfo` に設定することができます。

### ■ 修正方法

リエントランシー攻撃を防ぐために、`ReentrancyGuard.sol`で定義されているような、修飾子を`lend()`メソッドにも適用すること。  

https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol



