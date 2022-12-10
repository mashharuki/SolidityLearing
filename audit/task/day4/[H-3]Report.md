## [H-3] 借り手が自分自身の貸し手となり、リエントランシー攻撃によりbuyoutから資金を盗むことができる脆弱性

### ■ カテゴリー

Reentrancy

### ■ 条件

`loanAssetContractAddress`に指定されているトークンの制御権を受け取り手に移してしまうこと

### ■ ハッキングの詳細

```sol
    } else {
        ERC20(loan.loanAssetContractAddress).safeTransferFrom(
            msg.sender,
            currentLoanOwner,
            accumulatedInterest + previousLoanAmount
        );
    }
    ILendTicket(lendTicketContract).loanFacilitatorTransfer(currentLoanOwner, sendLendTicketTo, loanId);
```

借り手が自分のローンを貸した場合、貸し出しチケットの所有権が新しい貸し手に移る前に、返済してローンを終了させることができます。借り手は、NFT＋融資額＋経過利子を保有することになります。

### ■ 修正方法

- リエントランシー攻撃を防ぐために、`ReentrancyGuard.sol`で定義されているような、修飾子を`lend()`メソッドにも適用すること。
- requrire文を使って、貸し手と借り手が同じアカウントでないことをチェックする一文を入れる
- lendTicektを移転するロジックを元の貸し手に資金を移転する前に挟み込む

https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol

```sol
require(msg.sender != currentLoanOwner, "msg.sender must be not currentLoanOwner address!")
```
