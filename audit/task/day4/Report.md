# Day4 Task Report

### 作成者

sho, mashharuki (I-Team)

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

攻撃者が既に `lend()` を呼び出している場合、任意の貸し手が攻撃者の保有する債権を買い取ろうとすると、攻撃者は reentrancy 攻撃によって `loanInfo` を操作することができます。攻撃者は、買い取りを希望する貸し手が予期しないような悪い値 (例えば、非常に長い期間や0金利) を `lendInfo` に設定することができます。

### ■ 修正方法

リエントランシー攻撃を防ぐために、`ReentrancyGuard.sol`で定義されているような、修飾子を`lend()`メソッドにも適用すること。  

https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol

```sol
// SPDX-License-Identifier: MIT
// ReentrancyGuard.sol

pragma solidity ^0.8.0;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}
```

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
- require文を使って、貸し手と借り手が同じアカウントでないことをチェックする一文を入れる
- lendTicketを移転するロジックを元の貸し手に資金を移転する前に挟み込む

https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol

```sol
require(msg.sender != currentLoanOwner, "msg.sender must be not currentLoanOwner address!")
```

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

## [M-2] トークンの転送に掛かる手数料を制御していない脆弱性

### ■ カテゴリー

ERC20

### ■ 条件

fee on transferをサポートするトークンアドレスを使って`lend()`メソッドを呼び出した場合に、`NFTLoanFacilitator`に設定されているfeeよりもトークンに設定されているfeeの方が大きい場合。

### ■ ハッキングの詳細

```sol
    ERC20(loanAssetContractAddress).safeTransferFrom(msg.sender, address(this), amount);
    uint256 facilitatorTake = amount * originationFeeRate / SCALAR;
    ERC20(loanAssetContractAddress).safeTransfer(
        IERC721(borrowTicketContract).ownerOf(loanId),
        amount - facilitatorTake
    );
```

借り手は任意のアセットトークンを指定できるので、fee on transferをサポートするトークンでローンが作成される可能性があります。もし、fee on transfer のアセットトークンが選択された場合、プロトコルは最初の `lend()` 呼び出しで失敗するポイントを含んでいます。

### ■ 修正方法

originationFeeを計算した後、トークンに設定されているfeeOnTransfer以上の値になっていることをチェックするようにする。

## [M-3] closeLoan()でsendCollateralToがERC721対応のコントラクトアドレスがどうかチェックされていないため、ユーザの担保NFTが凍結される脆弱性

### ■ カテゴリー

ERC721

### ■ 条件

`IERC721(loan.collateralContractAddress).transferFrom`によってNFTを移転させる先のアドレスにIERC721に準拠していないアドレスが割り当てられていた場合。

### ■ ハッキングの詳細

```sol
function closeLoan(uint256 loanId, address sendCollateralTo) external override notClosed(loanId) {
    require(IERC721(borrowTicketContract).ownerOf(loanId) == msg.sender,
    "NFTLoanFacilitator: borrow ticket holder only");
    Loan storage loan = loanInfo[loanId];
    require(loan.lastAccumulatedTimestamp == 0, "NFTLoanFacilitator: has lender, use repayAndCloseLoan");
    
    loan.closed = true;
    IERC721(loan.collateralContractAddress).transferFrom(address(this), sendCollateralTo, loan.collateralTokenId);
    emit Close(loanId);
}
```

`sendCollateralTo` は、`closeLoan()`が呼ばれたときに担保 NFT を受け取ります。ただし、`sendCollateralTo` が ERC721 をサポートしないコントラクトのアドレスである場合、担保 NFT をコントラクト内で凍結されてしまう。

### ■ 修正方法

`transferFrom`メソッドではなく、`safeTransferFrom`メソッドを使用するように修正する。

```sol
function closeLoan(uint256 loanId, address sendCollateralTo) external override notClosed(loanId) {
    require(IERC721(borrowTicketContract).ownerOf(loanId) == msg.sender,
    "NFTLoanFacilitator: borrow ticket holder only");
    Loan storage loan = loanInfo[loanId];
    require(loan.lastAccumulatedTimestamp == 0, "NFTLoanFacilitator: has lender, use repayAndCloseLoan");
    
    loan.closed = true;
    IERC721(loan.collateralContractAddress).safeTransferFrom(address(this), sendCollateralTo, loan.collateralTokenId);
    emit Close(loanId);
}
```

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

## [M-7] mintBorrowTicketToはonERC721Receivedメソッドを持たないコントラクトである可能性があり、これによりBorrowTicket NFTが凍結され、ユーザーの資金が危険にさらされる可能性があります。

### ■ カテゴリー

ERC721

### ■ 条件

`_mint`メソッドによりミントする先のアドレスが、IERC721に対応しているコントラクト以外である場合

### ■ ハッキングの詳細

```sol
function mint(address to, uint256 tokenId) external override loanFacilitatorOnly {
    _mint(to, tokenId);
}
```

`NFTLoanFacilitator.sol`の102行目あたりで`_mint`メソッドを呼んでいるが、ここでtoのアドレスがIERC721に対応していないと適切ではないアドレスにNFTをミントしてしまうことになる。(凍結状態となる。)

### ■ 修正方法

`_mint`メソッドではなく、`_safeMint`を使うようにすること。

```sol
function mint(address to, uint256 tokenId) external override loanFacilitatorOnly {
    _safeMint(to, tokenId);
}
```
