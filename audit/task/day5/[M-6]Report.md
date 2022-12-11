## [M-6] 契約の所有者はユーザがstrikeを撤回するのをブロックすることができる脆弱性

### ■ カテゴリー

DoS

### ■ 条件

- `onwer()`にゼロアドレスを設定している場合
- `baseAsset`がERC777準拠のトークンである場合

### ■ ハッキングの詳細

正常であればPuttyコントラクトにエスクローされたstrikeをユーザーが引き出す際、Putty はstrikeから一定額の手数料を徴収することになります。手数料はまずコントラクトに送られ、残りのstrikeはその後ユーザーに送られます。しかし、上記条件を満たした場合には正常に動かない場合があります。

```sol
function withdraw(Order memory order) public {
	..SNIP..
	// transfer strike to owner if put is expired or call is exercised
	if ((order.isCall && isExercised) || (!order.isCall && !isExercised)) {
		// send the fee to the admin/DAO if fee is greater than 0%
		uint256 feeAmount = 0;
		if (fee > 0) {
			feeAmount = (order.strike * fee) / 1000;
			ERC20(order.baseAsset).safeTransfer(owner(), feeAmount);
		}
		ERC20(order.baseAsset).safeTransfer(msg.sender, order.strike - feeAmount);
		return;
	}
	..SNIP..
}
```

ERC20に準拠しているトークンであれば、ゼロアドレスに送金することを許可していないので`reverts`が発生します。

`baseAsset`がERC77トークン準拠のアドレスであの場合`owner()`の結果得られるrecipientは、PuttyV2コントラクトがrecipientに料金を送信しようとすると`reverts`が発生します。これにより`withdraw()`メソッドを実行した場合も`reverts`が発生します。その結果、誰もコントラクトから行使額を引き出すことができなくなります。  

**注：owner()はコントラクトまたはEOAアカウントを指すことができます。コントラクトを指すことで、誰かがトークンを送るたびにコントラクトが元に戻るようなロジックを実装することができます。**   

ERC777 には `tokensReceived` フックがあり、誰かが受信者にトークンを送信するたびに受信者に通知されます。  

**ERC777とは**  
コントラクト自体がトークンの送信・受信を行うことができるという規格
 
### ■ 修正方法

feeを回収するために、`withdraw`パターンを採用すること。  

出金時にオーナーアドレスに直接手数料を転送するのではなく、オーナーが受け取ることができる手数料の金額をステート変数に保存します。そして、オーナーがPuttyV2契約から手数料を引き出すことができる新しい関数を実装します。

```sol
mapping(address => uint256) public ownerFees;

function withdraw(Order memory order) public {
	..SNIP..
    // transfer strike to owner if put is expired or call is exercised
    if ((order.isCall && isExercised) || (!order.isCall && !isExercised)) {
        // send the fee to the admin/DAO if fee is greater than 0%
        uint256 feeAmount = 0;
        if (fee > 0) {
            feeAmount = (order.strike * fee) / 1000;
            ownerFees[order.baseAsset] += feeAmount
        }
        ERC20(order.baseAsset).safeTransfer(msg.sender, order.strike - feeAmount);
        return;
    }
    ..SNIP..
}

function withdrawFee(address baseAsset) public onlyOwner {
	uint256 _feeAmount = ownerFees[baseAsset];
	ownerFees[baseAsset] = 0;
	ERC20(baseAsset).safeTransfer(owner(), _feeAmount);
}
```