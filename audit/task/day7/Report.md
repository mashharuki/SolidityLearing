# [F-Team] Day7 Task Report

### 作成者

mugi, Kyok, masaru, mashharuki

## [FTeam-H1] 【Access Control】 `approvedTokens`に何も登録できずコントラクトが機能しなくなる脆弱性

## 要約

`addApprovedTokens()`メソッドを呼び出せず、`approvedTokens`に何も登録できずコントラクトが機能しなくなる脆弱性

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

## [FTeam-H2] 預かり金の全額引き出しができない

## 要約

`canWithdrawAmount`が`info.amount`より大きい場合、預かり金が全額引き出せなくなる。

## バグの詳細
`canWithdrawAmount`が`info.amount`より大きい場合に、預かり金の引き出しをするようになっているため、全額引き出しができない

## インパクト
預かり金が正しく引き出せなくなる

## 対象となるコード
https://gist.github.com/Tomosuke0930/5624c8fde570aae10e2cec00c4c2758a#file-unsecure-sol-L114

## 使用したツール
特になし

## 改善方法
比較演算子を変更する。

* before
```solo=
require(_info.amount < canWithdrawAmount, "ERROR");
```

* after
```solo=
require(_info.amount <= canWithdrawAmount, "ERROR");
```

## [FTeam-H3] 送金後に残高の更新がされていない

## 要約

資産の送金後、mapping変数の値が更新されていないので引き出し後の残高が変更されていない。

## バグの詳細
送金後、`depositAmt[msg.sender][_token]`の値が更新されていないため、引き出し後の残高が変わらない

## インパクト
送金をしても残高が減らない状態になるため、重大

## 対象となるコード
https://gist.github.com/Tomosuke0930/5624c8fde570aae10e2cec00c4c2758a#file-unsecure-sol-L116-L117

## 使用したツール
特になし

## 改善方法

* before
```solo=
function withdraw(
    address _to,
    uint _amount,
    bool _isETH,
    address _token
  ) public {
    if (!_isXXX(_token, whitelist)) revert();
    TransferInfo memory info = TransferInfo({
        isETH: _isETH,
        token: _token;
        from: address(this), 
        amount: _amount,
        to: _to,
    });
    uint canWithdrawAmount = depositAmt[msg.sender][_token].amount;
    require(_info.amount < canWithdrawAmount, "ERROR");
    canWithdrawAmount = 0;
    _tokenTransfer(_info);
    uint rewardAmount = getReward(_token);
    IERC20(BBBToken).transfer(msg.sender, rewardAmount);
  }
```

* after
```solo=
function withdraw(
    address _to,
    uint _amount,
    bool _isETH,
    address _token
  ) public {
    if (!_isXXX(_token, whitelist)) revert();
    TransferInfo memory info = TransferInfo({
        isETH: _isETH,
        token: _token;
        from: address(this), 
        amount: _amount,
        to: _to,
    });
    uint canWithdrawAmount = depositAmt[msg.sender][_token].amount;
    require(_info.amount < canWithdrawAmount, "ERROR");
    canWithdrawAmount = 0;
    
    //追加
    depositAmt[msg.sender][_token].amount -= _amount;
    
    _tokenTransfer(_info);
    
    uint rewardAmount = getReward(_token);
    IERC20(BBBToken).transfer(msg.sender, rewardAmount);
  }

```

## [FTeam-H4]  Reentrancyー攻撃により資金を盗むことができてしまう

## 要約

C-E-Iパターンに沿って実装されていないため`withdraw`実行時にReentrancy攻撃が発生する可能性がある。

## バグの詳細
攻撃者に`withdraw`関数を呼ばれた場合、Reentrancy攻撃により、資金を盗まれる

## インパクト
資金を盗まれる可能性があるため、重大

## 対象となるコード
https://gist.github.com/Tomosuke0930/5624c8fde570aae10e2cec00c4c2758a#file-unsecure-sol-L116

## 使用したツール
特になし

## 改善方法
OpenZeppelin のnonReentrant modifier を使用する
https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol#L50-L54

```solidity=
//追加
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// ReentrancyGuardの追加
contract BBB is ReentrancyGuard{
...

function withdraw(
    address _to,
    uint _amount,
    bool _isETH,
    address _token
    //追加
  ) public nonReentrant {
    if (!_isXXX(_token, whitelist)) revert();
    TransferInfo memory info = TransferInfo({
        isETH: _isETH,
        token: _token;
        from: address(this), 
        amount: _amount,
        to: _to,
    });
    uint canWithdrawAmount = depositAmt[msg.sender][_token].amount;
    require(_info.amount < canWithdrawAmount, "ERROR");
    canWithdrawAmount = 0;
    _tokenTransfer(_info);
    uint rewardAmount = getReward(_token);
    IERC20(BBBToken).transfer(msg.sender, rewardAmount);
  }
}
```

## [FTeam-H5]`depositAmt`が上書きされる

## 要約
`deposit()`内でdeposit Amountを保存するが、引き出し終わる前に同じトークンを預け入れると、最新の預け入れ金額に上書きされてしまう

## バグの詳細
PoCとしては以下となる

1. Aliceが10USDT depositする
`deposit(10, USDT contract address, false)`
2. depositAmt[Alice][USDT contract address] = 10となる
3. Aliceが20USDT depositする
`deposit(10, USDT contract address, false)`
4. deposit[Alice][USDT contract address] = 20となる

AliceがwithdrawできるUSDTは最大でも20となる。  
先に預けた10USDTがコントラクトの中にロックされてしまう

## インパクト
コントラクトの中にユーザーの資金がロックされて、ユーザーにとって損失があるので重大

## 対象となるコード
https://gist.github.com/Tomosuke0930/5624c8fde570aae10e2cec00c4c2758a#file-unsecure-sol-L96

## 使用したツール
特になし

## 改善方法
あるトークンをdepositしている状態であるのなら、同じトークンを`deposit()`することができないようにチェックする。  
Check depositAmt[msg.sender][_token] == 0
```solidity
function deposit(uint _amount, address _token, bool _isETH) public {
    require(depositAmt[msg.sender][_token] == 0, "has already depositted");
    // ......
}
```

## [FTeam-H6] Checkが不足しているため、預入額とEther送金額が一致しない可能性がある

## 要約
`deposit()`でEtherを預けた値(msg.value)と、depositAmtに格納された預入額が一致しない場合がある  
https://gist.github.com/Tomosuke0930/5624c8fde570aae10e2cec00c4c2758a#file-unsecure-sol-L95

## バグの詳細
`deposit()`が第3引数をtrueとして実行することは、`_tokenTransfer()`を呼び出してEtherがコントラクトに送金されようとすることを意味する  
その際に、`_tokenTransfer()`でも以下の様に_info.amount分のEtherを送金している。
```solidity
  function _tokenTransfer(TransferInfo memory _info) private {
    if (_info.isETH) {
      (bool success, ) = _info.to.call{ value: _info.amount }("");
      require(success, "Failed");
    } else {
      IERC20(_info.token).transferFrom(_info.from, _info.to, _info.amount);
    }
  }
}
```
しかし、_info.amountが、`deposit()`の際のmsg.valueと一致するとは限らない。  

そのため、以下のようなAttackを行うことが可能
1. deposit(1000, address(0), true){msg.value : 1 wei} で実行
2. withdraw(msg.sender,900,true,address(0)) を実行
3. 899wei分Attackerは儲かることができる


## インパクト
Attackerが余分に引き出しすることが可能なので、重大なエラー

## 対象となるコード
https://gist.github.com/Tomosuke0930/5624c8fde570aae10e2cec00c4c2758a#file-unsecure-sol-L82

## 使用したツール
特になし

## 改善方法
Ether送信されているときは、以下のCheckを追加する  
Check msg.value == _amount
```solidity
require(msg.value == _amount, "incorrect amount of ether");
```

## [FTeam-H7] 長く預けると付与されるRewardが減ってしまう計算式になっている

## 要約
`getReward`内の計算式だと対象期間が分母にセットされており、期間が増えるほどrewardが減ってしまう

## バグの詳細
`reward = (REWARD_RATE / (block.timestamp - lastTime)) * amount;`
`REWARD_RATE`は50がセットされている。
`block.timestamp`の単位は秒なので、例えば1秒しか預けなければamountの50倍のrewardになるが、３０日間預けるとamountの約50000分の1(50/(30*24*60*60))のrewardに減ってしまう。

## インパクト
想定されたRewardではないものが付与される

## 対象となるコード

```Solidity
  reward = (REWARD_RATE / (block.timestamp - lastTime)) * amount;
```

## 使用したツール
特になし

## 改善方法
rewardは預け入れの時間に比例して大きくなるように計算式を修正する。
```Solidity
  reward = REWARD_RATE * (block.timestamp - lastTime) * amount;
```

## [FTeam-M1] 【Access Control】 `approvedTokes`に悪意あるトークンが登録される可能性がある脆弱性

## 要約

JPYC, USDC, USDT以外のトークンのアドレスが`approvedTokes`に登録される可能性がある。

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

## [FTeam-M2] 【DoS】　無限大ループが発生し、ユーザーが資産を預けることも引き出すこともできなくなってしまうDoSが発生する脆弱性

## 要約

`whitelist`に無数のトークンアドレスが登録されてしまった場合にDoSが発生し、資産が引き出しできなくなってしまう可能性がある。

## バグの詳細

`addApprovedTokens()`と`addWhitelist()`を利用して、BBBコントラクトで使用するトークンのアドレスのホワイトリストを作成しているが、登録できるトークンの数に上限値が設定されていないため、無数のトークンアドレスを登録できてしまう脆弱性がある。

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

## [FTeam-M3] `deposit()`関数にpayableがついていない

## 要約
`deposit()`はEtherをBBB contractに送金する場合もあるのに、payable identifierがついていない

## バグの詳細
`deposit()`が第3引数をtrueとして実行することは、Etherがコントラクトにdepositされることを意味する。  
しかし、payable identifierがないためEhterをコントラクトに送ることができない。

## インパクト
Attackされることはないが、ドキュメントの仕様と大きく異なる

## 対象となるコード
https://gist.github.com/Tomosuke0930/5624c8fde570aae10e2cec00c4c2758a#file-unsecure-sol-L82

## 使用したツール
特になし

## 改善方法
`deposit()`にpayable identifierを付ける。
```solidity
function deposit(uint _amount, address _token, bool _isETH) public payable {
```

## [FTeam-M3] BBB contractに`fallback()`がない

## 要約
`deposit()`が実行されるとBBB contractはEtherを受け取ろう場合があるが、fallback()がないため、受け取れずにrevertする

## バグの詳細

`deposit()`が第3引数をtrueとして実行することは、`_tokenTransfer()`を呼び出してEtherがコントラクトに送金されようとすることを意味する  

https://gist.github.com/Tomosuke0930/5624c8fde570aae10e2cec00c4c2758a#file-unsecure-sol-L126  

しかし、BBBにfallback()がないためEhterをコントラクトに送ることができない。  

## インパクト
Attackされることはないが、ドキュメントの仕様と大きく異なる

## 対象となるコード
https://gist.github.com/Tomosuke0930/5624c8fde570aae10e2cec00c4c2758a#file-unsecure-sol-L126

## 使用したツール
特になし

## 改善方法
BBB contract内にfallback関数を追加する
```solidity
fallback() external payable {}
```

## [FTeam-M3] 不適切なCheckによって`deposit()`でEtherを送金できなくなっている

## 要約
`deposit()`でEtherを預けようとしても、83行目のckeckが不適切なので、送金できない  
https://gist.github.com/Tomosuke0930/5624c8fde570aae10e2cec00c4c2758a#file-unsecure-sol-L83

## バグの詳細
`deposit()`が第3引数をtrueとして実行することは、`_tokenTransfer()`を呼び出してEtherがコントラクトに送金されようとすることを意味する  

https://gist.github.com/Tomosuke0930/5624c8fde570aae10e2cec00c4c2758a#file-unsecure-sol-L83

しかし、83行目のckeckで、Etherは`whiteList`に含まれていないためrevertしてしまう。  
`if (!_isXXX(_token, whitelist)) revert();`

## インパクト
Attackされることはないが、ドキュメントの仕様と大きく異なる

## 対象となるコード
https://gist.github.com/Tomosuke0930/5624c8fde570aae10e2cec00c4c2758a#file-unsecure-sol-L83

## 使用したツール
特になし

## 改善方法
Ether以外のTokenが送信されているときのみ、whiteListと照合するチェックを行う
```solidity
if (!_isEther && !_isXXX(_token, whitelist)) revert();
```

## [FTeam-L1]  【Access Control】 ペグが外れて`approvedTokens`に登録されているトークンの情報を取り除けない問題

## バグの詳細

`addApprovedTokens()`の様にトークンの情報を追加できるメソッドはあるが、登録した情報を取り消すことができない状態になっている。

## インパクト

致命的な問題にはつながりづらいが、登録されているトークンに問題が発生した場合に`approvedTokens`に登録され続けることになるので意図しない不利益が発生する可能性がある。

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

`approvedTokens`に登録されているデータを取り消すことができるようにするロジックを加える。  
具体的には次の通り。  

1. 配列の要素とindex情報を紐付けるmapping変数の追加
2. `delete`オペレーションを実装した`removeApprovedTokens`メソッドの追加

- ■ 修正後のコード

```diff

+ mapping (address => uint256) public arrayIndexes;

/// @notice  approvedTokens配列にtokenを使いするために使用します
/// @dev     ownerだけが実行できます。 
function addApprovedTokens(address _token) private {
    if (msg.sender != owner) revert();
+    uint id = sellers.length;
+    arrayIndexes[_addr] = id;
    approvedTokens.push(_token);
}

+ function removeApprovedTokens(address _token) private {
+    if (msg.sender != owner) revert();
+     uint id = arrayIndexes[_addr];
+    approvedTokens.push(_token);
+ }
```

## [FTeam-L2] getRewardの対象となるTokenがWhitelistにない可能性がある

## 要約
WhiteListのチェックをしていないためgetRewardの対象TokenがWhitelistにない可能性がある

## バグの詳細
getRewardの引数にセットされたアドレスがホワイトリスト外のアドレスである可能性がある

## インパクト
想定していないTokenをgetRewardにセットされる可能性がある（戻り値は０になる）

## 対象となるコード

```Solidity
  function getReward(address token) public view returns (uint reward) {
    uint amount = depositAmt[msg.sender][token].amount;
    uint lastTime = depositAmt[msg.sender][token].lastTime;
    reward = (REWARD_RATE / (block.timestamp - lastTime)) * amount;
  }
```

## 使用したツール
特になし

## 改善方法
`deposit`関数と同様、ホワイトリストにないTokenの場合revokeする処理を`getReward`に加える

```if (!_isXXX(token, whitelist)) revert();```

