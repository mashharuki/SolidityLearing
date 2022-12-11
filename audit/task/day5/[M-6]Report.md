## [M-6] 契約の所有者はユーザがストライクを撤回するのをブロックすることができる脆弱性

### ■ カテゴリー

DoS

### ■ 条件

- `onwer()`にゼロアドレスを設定している場合
- `baseAsset`がERC777準拠のトークンである場合

### ■ ハッキングの詳細

正常であればPuttyコントラクトにエスクローされたストライクをユーザーが引き出す際、Putty はストライク額から一定額の手数料を徴収する。手数料はまずコントラクトに送られ、残りのストライク金額はその後ユーザーに送られます。しかし、上記条件を満たした場合にはこれをブロックすることができる。

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

ERC20に準拠しているトークンであれば、ゼロアドレスに送金することを許可していないので`reverts`が発生する。  

baseAssetがERC77トークンであると仮定すると、この場合owner()であるrecipientは、PuttyV2コントラクトがrecipientに料金を送信しようとするたびに、常にリバートすることができます。これによって、引き出し関数もリバートされることになります。その結果、誰もコントラクトから行使額を引き出すことができなくなる。  

**注：owner()はコントラクトまたはEOAアカウントを指すことができます。コントラクトを指すことで、誰かがトークンを送るたびにコントラクトが元に戻るようなロジックを実装することができます。**   

ERC777 には `tokensReceived` フックがあり、誰かが受信者にトークンを送信するたびに受信者に通知されます。  

**ERC777とは**  
コントラクト自体がトークンの送信・受信をできるという規格
 
### ■ 修正方法

feeを回収するために、`withdraw`パターンを採用すること。  

出金時にオーナーアドレスに直接手数料を転送するのではなく、オーナーが受け取ることができる手数料の金額をステート変数に保存します。そして、オーナーがPuttyV2契約から手数料を引き出すことができる新しい関数を実装します。

次のような実装を考えてみましょう。以下の例では、オーナーへの手数料の送金結果（成功・失敗）は、ユーザーのストライク引き出し処理に影響しないため、オーナーがユーザー拒否を行う方法はない。

これにより、ユーザーはPutty内に保管されている資金の安全性について、より確実で信頼できるようになります。

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