// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

contract BBB {

  /*********************************************************************************************
   ************************************   VARIABLES     ****************************************
   *********************************************************************************************/

  uint constant REWARD_RATE = 50;
  // 関数のaddressは適当です
  address constant BBBToken = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
  // ここ要チェック
  address owner = msg.sender;
  address[] approvedTokens; /// JPYC, USDC, USDTのみがownerからapproveされます
  address[] whitelist;
  mapping(address => mapping(address => DepostInfo)) depositAmt;

  /*********************************************************************************************
   ************************************     STRUCT     ****************************************
   *********************************************************************************************/

  struct DepostInfo {
    uint lastTime;      /// 32 bytes
    uint amount;        /// 32 bytes
  }

  struct TransferInfo {
    bool isETH;         /// 32 bytes
    uint amount;        /// 32 bytes
    address token;      /// 20 bytes
    address from;       /// 20 bytes
    address to;         /// 20 bytes
  }

  /*********************************************************************************************
   *********************************   OWNER FUNCTIONS     *************************************
   *********************************************************************************************/

  /// @notice  approvedTokens配列にtokenを使いするために使用します
  /// @dev     ownerだけが実行できます。 ← privateにしているので外部から呼び出せない？？ 登録できないのではないか？？どうやって呼び出して追加する??
  function addApprovedTokens(address _token) private {
    // ここ怪しそう・・　ownerのアドレスを設定しなくて良い？？ modifyerとか使った方が良さそう owner書き換えられそう・・・。
    if (msg.sender != owner) revert();
    approvedTokens.push(_token);
  }

  /*********************************************************************************************
   *******************************   VIEW | PURE FUNCTIONS     *********************************
   *********************************************************************************************/

  /// @notice  Rewardを獲得するためのメソッド (引数に設定されているアドレスがホワイトリストに登録ずみのアドレスであること確認する必要があるかも)
  /// @dev     Can call only owner
  /// @return  reward
  function getReward(address token) public view returns (uint reward) {
    uint amount = depositAmt[msg.sender][token].amount;
    uint lastTime = depositAmt[msg.sender][token].lastTime;
    // ここ怪しそう・・。 block.timestampを使ってはだめで時間加重平均で算出した方が良い？？
    reward = (REWARD_RATE / (block.timestamp - lastTime)) * amount;
  }

  function _isXXX(
    address _token,
    address[] memory _xxx
  ) private pure returns (bool) {
    uint length = _xxx.length;
    // ここ怪しそう
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
   * owner以外が追加できてしまうので任意の草コインも登録できてしまうのではないか？？？
   */
  function addWhitelist(address _token) public {
    if (!_isXXX(_token, approvedTokens)) revert();
    whitelist.push(_token);
  }

  /**
   * 
   */
  function deposit(uint _amount, address _token, bool _isETH) public {
    if (!_isXXX(_token, whitelist)) revert();
    DepostInfo memory depositInfo;

    TransferInfo memory info = TransferInfo({
        isETH: _isETH,
        token: _token,
        from: msg.sender, 
        amount: _amount,
        to: address(this)
    });

    _tokenTransfer(info);
    // ここ怪しそう・・。
    depositInfo.lastTime = uint40(block.timestamp);
    depositInfo.amount = _amount;
    depositAmt[msg.sender][_token] = depositInfo;
  }

  // 誰でもwithdrawできて良いのか？？ 何かしらで制限する必要ありそう・・！
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
    require(info.amount < canWithdrawAmount, "ERROR");

    canWithdrawAmount = 0;
    _tokenTransfer(info);
    uint rewardAmount = getReward(_token);
    // ここsafeTransferFromじゃなくて良い？？
    IERC20(BBBToken).transfer(msg.sender, rewardAmount);
    // 最後に情報などを更新しなくても良いか？
  }

  /*********************************************************************************************
   *********************************   PRIVATE FUNCTIONS     ***********************************
   *********************************************************************************************/
  function _tokenTransfer(TransferInfo memory _info) private {
    if (_info.isETH) {
      (bool success, ) = _info.to.call{ value: _info.amount }("");
      require(success, "Failed");
    } else {
      // ここsafeTransferFromじゃなくて良い？？
      IERC20(_info.token).transferFrom(_info.from, _info.to, _info.amount);
    }
  }
}

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