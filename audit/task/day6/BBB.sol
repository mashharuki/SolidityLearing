// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

/**
 * BBB コントラクト
 */
contract BBB {

  /*********************************************************************************************
   ************************************   VARIABLES     ****************************************
   *********************************************************************************************/
  // Reward 用の定数
  // @audit 50という値で良いのか？？ 桁が違うのではないか？
  uint constant REWARD_RATE = 50;
  // 関数のaddressは適当です(すでにデプロイ済みである想定)
  address constant BBBToken = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
  // ownerには、このコントラクトをデプロイしたアドレスを指定
  address owner = msg.sender;
  /// JPYC, USDC, USDTのみがownerからapproveされます
  address[] approvedTokens; 
  // ホワイトリストに設定されたトークンアドレスを格納する変数(怪しそう・・。)
  address[] whitelist;
  // 各アドレスのdepositAmtを保有するmapping変数
  mapping(address => mapping(address => DepostInfo)) depositAmt;

  /*********************************************************************************************
   ************************************     STRUCT     ****************************************
   *********************************************************************************************/

  struct DepostInfo {
    uint lastTime;      /// 32 bytes
    uint amount;        /// 32 bytes
  }

  struct TransferInfo {
    bool isETH;         /// 32 bytes @audit uintではなくboolでは？
    uint amount;        /// 32 bytes
    address token;      /// 20 bytes
    address from;       /// 20 bytes
    address to;         /// 20 bytes
  }

  /*********************************************************************************************
   *********************************   OWNER FUNCTIONS     *************************************
   *********************************************************************************************/

  /// @notice  approvedTokens配列にtokenを使いするために使用します
  /// @dev     ownerだけが実行できます。 ownerが悪意あるコードを登録する可能性もある コンストラクターがなくownerが変更される可能性あるかも
  function addApprovedTokens(address _token) private {
    if (msg.sender != owner) revert();
    // @audit JPYC, USDC, USDTのいずれかのアドレスであるかを確認するロジックはいらないのか？？
    // @audit ownerアドレスを無限に登録できてしまうので、上限値を設ける必要があるのではないか？
    // @audit このaddApprovedTokensって他にどこから呼び出す??
    // @audit removeが必要では？
    approvedTokens.push(_token);
  }

  /*********************************************************************************************
   *******************************   VIEW | PURE FUNCTIONS     *********************************
   *********************************************************************************************/

  /// @notice  Rewardを獲得するためのメソッド (引数に設定されているアドレスがホワイトリストに登録ずみのアドレスであること確認する必要があるかも)
  /// @dev     Can call only owner
  /// @return  reward 
  function getReward(address token) public view returns (uint reward) {
    // @audit 引数にセットされたアドレスがホワイトリスト外のアドレスであることを想定した方が良さそう・・。
    uint amount = depositAmt[msg.sender][token].amount;
    uint lastTime = depositAmt[msg.sender][token].lastTime;
    // ここ怪しそう・・。 block.timestampを使ってはだめで時間加重平均で算出した方が良い？？
    // @audit amountが0であった時にエラーが発生しそうなのでチェック入れた方が良い。 (計算式がおかしい？時間が経てば減るロジックになっている。)
    reward = (REWARD_RATE / (block.timestamp - lastTime)) * amount;
  }

  function _isXXX(
    address _token,
    address[] memory _xxx
  ) private pure returns (bool) {
    uint length = _xxx.length;
    // _xxxの配列の個数が大きい場合には無限ループが発生するバグがありそうので、lengthの上限値をチェックするロジック入れた方が良さそう・・・。
    for (uint i; i < length; ) {
      if (_token == _xxx[i]) return true;
      unchecked {
        ++i;
      }
    }
    return false;
  }

  /*********************************************************************************************
   *********************************   PUBLIC FUNCTIONS     ************************************
   *********************************************************************************************/

  /**
   * owner以外が追加できてしまうので任意の草コインも登録できてしまうのではないか？？？　→ approvedTokensで管理しているのでそんなことなし！
   */
  function addWhitelist(address _token) public {
    if (!_isXXX(_token, approvedTokens)) revert();
    // @audit removeはいらないのか？
    // @audit 整合性を確認しなくては良いのか？
    whitelist.push(_token);
  }

  /**
   * depositするメソッド
   */
  function deposit(uint _amount, address _token, bool _isETH) public {
    if (!_isXXX(_token, whitelist)) revert();
    DepostInfo memory depositInfo;

    // @audit ethの場合は、amountはmsg.valueでなくては良いのか？
    // require(_amount == msg.value)

    TransferInfo memory info = TransferInfo({
        isETH: _isETH,
        token: _token,
        from: msg.sender, 
        amount: _amount,
        to: address(this)
    });
    // C-E-Iパターンに従って実装されていないので、depositInfoが更新されずにrevertsが発生する可能性あり
    _tokenTransfer(info);
    // @audit データが上書きされてしまうのではないか？
    depositInfo.lastTime = uint40(block.timestamp);
    depositInfo.amount = _amount;
    depositAmt[msg.sender][_token] = depositInfo;
  }

  // @audit 誰でもwithdrawできて良いのか？？ 何かしらで制限する必要ありそう・・！ mapping変数などで管理する必要あり！
  function withdraw(
    address _to,
    uint _amount,
    bool _isETH,
    address _token
  ) public {
    if (!_isXXX(_token, whitelist)) revert();

    TransferInfo memory info = TransferInfo({
        isETH: _isETH,
        token: _token,
        from: address(this), 
        amount: _amount,
        to: _to
    });
    // この辺怪しそう・・。
    uint canWithdrawAmount = depositAmt[msg.sender][_token].amount;
    // @audit =も加えた方が良いのではないか？(全額引き出しができない？)
    require(info.amount < canWithdrawAmount, "ERROR");

    canWithdrawAmount = 0;
    // @audit リエントランシー攻撃の可能性あり
    _tokenTransfer(info);
    // @audit depositAmt[msg.sender][_token]の値を更新しなくても良いのか？
    // depositAmt[msg.sender][_token].amount -= _amount;

    // @audit rewardを分売するロジックは別で儲けた方が良い？
    uint rewardAmount = getReward(_token);
    IERC20(BBBToken).transfer(msg.sender, rewardAmount);
  }

  /*********************************************************************************************
   *********************************   PRIVATE FUNCTIONS     ***********************************
   *********************************************************************************************/

  function _tokenTransfer(TransferInfo memory _info) private {
    if (_info.isETH) {
      // 動くかチェック
      (bool success, ) = _info.to.call{ value: _info.amount }("");
      require(success, "Failed");
    } else {
      IERC20(_info.token).transferFrom(_info.from, _info.to, _info.amount);
    }
  }

  // @audit fallback関数がない
}

/**
 * インターフェースは、悪さはしていない。
 */
interface IERC20 {
  function totalSupply() external view returns (uint);

  function balanceOf(address account) external view returns (uint);

  function transfer(address recipient, uint amount) external returns (bool);

  function allowance(
    address owner,
    address spender
  ) external view returns (uint);

  function approve(address spender, uint amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}