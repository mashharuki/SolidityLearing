[Masaru-M#1] getRewardの対象となるTokenがWhitelistにない可能性がある
要約
WhiteListのチェックをしていないためgetRewardの対象TokenがWhitelistにない可能性がある

バグの詳細
getRewardの引数にセットされたアドレスがホワイトリスト外のアドレスである可能性がある

インパクト
悪意のあるTokenをgetRewardにセットされる可能性がある

対象となるコード
  function getReward(address token) public view returns (uint reward) {
    uint amount = depositAmt[msg.sender][token].amount;
    uint lastTime = depositAmt[msg.sender][token].lastTime;
    reward = (REWARD_RATE / (block.timestamp - lastTime)) * amount;
  }
使用したツール
特になし

改善方法
deposit関数と同様、ホワイトリストにないTokenの場合revokeする処理をgetRewardに加える

if (!_isXXX(token, whitelist)) revert();

[Masaru-M#2] 長く預けると付与されるRewardが減ってしまう計算式になっている
要約
getReward内の計算式だと対象期間が分母にセットされており、期間が増えるほどrewardが減ってしまう

バグの詳細
reward = (REWARD_RATE / (block.timestamp - lastTime)) * amount;
REWARD_RATEは50がセットされている。
block.timestampの単位は秒なので、例えば1秒しか預けなければamountの50倍のrewardになるが、３０日間預けるとamountの約50000分の1(50/(302460*60))のrewardに減ってしまう。

インパクト
想定されたRewardではないものが付与される

対象となるコード
  reward = (REWARD_RATE / (block.timestamp - lastTime)) * amount;
使用したツール
特になし

改善方法
rewardは預け入れの時間に比例して大きくなるように計算式を修正する。
  reward = REWARD_RATE * (block.timestamp - lastTime) * amount;
上記の修正に合わせ、50となっているREWARD_RATEを適切な値に見直す。例えば年間でamoutの10%程度を想定するなら以下のような値とする。
REWARD_RATE=0.1/(365*24*60*60) //およそ0.000000003 