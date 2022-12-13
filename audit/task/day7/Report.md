# [F-Team] Day7 Task Report

### 作成者

mugi, Kyok, masaru, mashharuki

## [FTeam-M1] 【Access Control】 `approvedTokes`に悪意あるトークンが登録される可能性がある脆弱性

## バグの詳細

`addApprovedTokens()`にて、BBBコントラクトで使用するトークンのアドレスを登録しているが、引数で渡されたトークンのアドレスが、JPYC, USDC, USDTのいずれかのアドレスであるかどうかを確認していないので、JPYC, USDC, USDT以外のトークンのアドレスが登録される可能性がある。

## インパクト

`addApprovedTokens()`を利用して`owner`権限を持つ管理者が、JPYC, USDC, USDT以外の悪意あるコードを持つトークンのアドレス情報を任意に登録できてしまう。

## 対象となるコード

```sol
/// @notice  approvedTokens配列にtokenを使いするために使用します
/// @dev     ownerだけが実行できます。 
function addApprovedTokens(address _token) private {
    if (msg.sender != owner) revert();
    approvedTokens.push(_token);
}
```

## 使用したツール
hardhat

## 改善方法

下記1〜3を満たすロジックをコントラクトに加えること。

1. JPYC, USDC, USDTのアドレスを格納した配列を作成する
2. 引数で渡されたアドレスが上記で作成した配列に含まれているかチェックする
3. 上記確認で問題なければ登録、なければ`reverts()`すること

- ■ 修正前のコード

```sol
function addApprovedTokens(address _token) private {
    if (msg.sender != owner) revert();
    approvedTokens.push(_token);
}
```

- ■ 修正後のコード

```diff
// JPYC, USDC, USDTのアドレスを格納した配列
+ address[] tokens = [
+    "x5B38Da6a701c568545dCfcB03FcB875f56beddC2",
+    "0x5B38Da6a701c568545dCfcB03FcB875f56beddC3",
+    "0x5B38Da6a701c568545dCfcB03FcB875f56beddC5"
+ ];

SHIP...

function addApprovedTokens(address _token) private {
    if (msg.sender != owner) revert();
+    if (!_isXXX(_token, tokens)) revert();

    approvedTokens.push(_token);
}
```

## [FTeam-M2] 【DoS】　無限大ループが発生し、ユーザーが資産を預けることも引き出すこともできなくなってしまうDoSが発生する脆弱性

## バグの詳細

`addApprovedTokens()`と`whitelist()`を利用して、BBBコントラクトで使用するトークンのアドレスのホワイトリストを作成しているが、登録できるトークンの数に上限値が設定されていないため、無数のトークンアドレスを登録できてしまう脆弱性がある。

## インパクト

`addApprovedTokens()`にて無数のトークンアドレスが登録された場合、`diposit()`や`withdraw()`で呼び出される`_isXXX()`にて無限ループ処理が発生し、ガス代が足りなくなって`reverts`が発生する可能性があり全てのユーザは資産を預けることも引き出すこともできなくなるDoSが可能性がある。

## 対象となるコード

```sol
/// @notice  approvedTokens配列にtokenを使いするために使用します
/// @dev     ownerだけが実行できます。 
function addApprovedTokens(address _token) private {
    if (msg.sender != owner) revert();
    approvedTokens.push(_token);
}
```

## 使用したツール
hardhat

## 改善方法

`approvedTokens`に3つのトークン以外が登録できないような条件を加える必要があるので、下記1〜3を満たすロジックをコントラクトに加えること。

1. JPYC, USDC, USDTのアドレスを格納した配列を作成する
2. 引数で渡されたアドレスが上記で作成した配列に含まれているかチェックする
3. 上記確認で問題なければ登録、なければ`reverts()`すること


- ■ 修正前のコード

```sol
function addApprovedTokens(address _token) private {
    if (msg.sender != owner) revert();
    approvedTokens.push(_token);
}
```

- ■ 修正後のコード

```diff
// JPYC, USDC, USDTのアドレスを格納した配列
+ address[] tokens = [
+    "x5B38Da6a701c568545dCfcB03FcB875f56beddC2",
+    "0x5B38Da6a701c568545dCfcB03FcB875f56beddC3",
+    "0x5B38Da6a701c568545dCfcB03FcB875f56beddC5"
+ ];

SHIP...

function addApprovedTokens(address _token) private {
    if (msg.sender != owner) revert();
+    if (!_isXXX(_token, tokens)) revert();

    approvedTokens.push(_token);
}
```


## [FTeam-H1] 【Access Control】 `addApprovedTokens()`メソッドを呼び出せず、`approvedTokens`に何も登録できずコントラクトが機能しなくなる脆弱性

## バグの詳細

`addApprovedTokens()`にて、BBBコントラクトで使用するトークンのアドレスを登録することを想定しているが、このメソッドの修飾子が`private`になっており且つこのコントラクト内にある他のメソッドからも呼び出されていないので、`approvedTokens`に何も登録できない状態となる。

## インパクト

`approvedTokens`に何も登録できなければ、`deposit()`も`withdraw()`も機能しなくなるため、実質BBBコントラクトが機能しない状態となってしまう。

## 対象となるコード

```sol
/// @notice  approvedTokens配列にtokenを使いするために使用します
/// @dev     ownerだけが実行できます。 
function addApprovedTokens(address _token) private {
    if (msg.sender != owner) revert();
    approvedTokens.push(_token);
}
```

## 使用したツール
hardhat

## 改善方法

`addApprovedTokens()`の修飾子を`private`から`public`に変更すること

- ■ 修正前のコード

```diff
    /// @notice  approvedTokens配列にtokenを使いするために使用します
    /// @dev     ownerだけが実行できます。 
-    function addApprovedTokens(address _token) private {
        if (msg.sender != owner) revert();
        approvedTokens.push(_token);
    }
```

- ■ 修正後のコード

```diff
    /// @notice  approvedTokens配列にtokenを使いするために使用します
    /// @dev     ownerだけが実行できます。 
+    function addApprovedTokens(address _token) public {
        if (msg.sender != owner) revert();
        approvedTokens.push(_token);
    }
```

## [FTeam-L1]  【Access Control】 誤ったアドレスを`approvedTokens`に登録してしまった場合に、取り消すことができない問題

## バグの詳細

`addApprovedTokens()`の様にトークンの情報を追加できるメソッドはあるが、誤登録で想定以外のトークンを登録してしまった場合に取り消すことができない状態になっている。

## インパクト

致命的な問題にはつながりづらいが、誤ったトークンのアドレスの情報が、`approvedTokens`に登録され続けることになるので意図しないトークンを使って`deposit()`や`withdraw()`が呼び出されて実行される可能性がある。

## 対象となるコード

```sol
/// @notice  approvedTokens配列にtokenを使いするために使用します
/// @dev     ownerだけが実行できます。 
function addApprovedTokens(address _token) private {
    if (msg.sender != owner) revert();
    approvedTokens.push(_token);
}
```

## 使用したツール
hardhat

## 改善方法

1. JPYC, USDC, USDTのアドレスを格納した配列を作成する
2. 引数で渡されたアドレスが上記で作成した配列に含まれているかチェックする
3. 上記確認で問題なければ登録、なければ`reverts()`すること


- ■ 修正前のコード

```sol
function addApprovedTokens(address _token) private {
    if (msg.sender != owner) revert();
    approvedTokens.push(_token);
}
```

- ■ 修正後のコード

```diff
// JPYC, USDC, USDTのアドレスを格納した配列
+ address[] tokens = [
+    0x5b38Da6a701C568545DCfCB03FcB875F56bEdDc2,
+    0x5B38da6A701C568545dCFCb03fCB875f56BeDDc3,
+    0x5B38Da6a701C568545DcFCb03fcb875F56BEDDc5
+ ];

SHIP...

function addApprovedTokens(address _token) private {
    if (msg.sender != owner) revert();
+    if (!_isXXX(_token, tokens)) revert();

    approvedTokens.push(_token);
}
```
