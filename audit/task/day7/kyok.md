UNCHAIN-BBB-DAY7 Report
Bug Bounty code4rena
[mugi-M1] 預かり金の全額引き出しができない
バグの詳細
canWithdrawAmountがinfo.amountより大きい場合に、預かり金の引き出しをするようになっているため、全額引き出しができない

インパクト
Medium Lisk

対象となるコード
https://gist.github.com/Tomosuke0930/5624c8fde570aae10e2cec00c4c2758a#file-unsecure-sol-L114

使用したツール
特になし

改善方法
比較演算子を変更する。

before
require(_info.amount < canWithdrawAmount, "ERROR");
after
require(_info.amount <= canWithdrawAmount, "ERROR");
[mugi-H1] 送金後に預金量の更新がされていない
バグの詳細
送金後、depositAmt[msg.sender][_token]の値が更新されていないため、引き出し後の預金量が変わらない

インパクト
High Lisk

対象となるコード
https://gist.github.com/Tomosuke0930/5624c8fde570aae10e2cec00c4c2758a#file-unsecure-sol-L116-L117

使用したツール
特になし

改善方法
before
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
after
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
    
    //追加
    depositAmt[msg.sender][_token].amount -= _amount;
    
    uint rewardAmount = getReward(_token);
    IERC20(BBBToken).transfer(msg.sender, rewardAmount);
  }

[mugi-H2] Reentrancyー攻撃により資金を盗むことができてしまう
バグの詳細
攻撃者にwithdraw関数を呼ばれた場合、Reentrancy攻撃により、資金を盗まれる

インパクト
High Lisk

対象となるコード
https://gist.github.com/Tomosuke0930/5624c8fde570aae10e2cec00c4c2758a#file-unsecure-sol-L116

使用したツール
特になし

改善方法
OpenZeppelin のnonReentrant modifier を使用する
https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol#L50-L54

//追加
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// ReentrancyGuardの追加
contract BBB is ,ReentrancyGuard{
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