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

