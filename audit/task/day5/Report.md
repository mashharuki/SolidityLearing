# Day5 Task Report

### 作成者

mashharuki

## [H-1] 取引に関する手数料が、putが実行されたときではなく、期限切れになったときに差し引かれる脆弱性

### ■ カテゴリー

ERC20

### ■ 条件

`order.isCall()` と `isExercised()` の値が `false`の時に発生する.

### ■ ハッキングの詳細

```sol
    // transfer strike to owner if put is expired or call is exercised
    if ((order.isCall && isExercised) || (!order.isCall && !isExercised)) {
        // send the fee to the admin/DAO if fee is greater than 0%
        uint256 feeAmount = 0;
        if (fee > 0) {
            feeAmount = (order.strike * fee) / 1000;
            ERC20(order.baseAsset).safeTransfer(owner(), feeAmount);
        }

        ERC20(order.baseAsset).safeTransfer(msg.sender, order.strike - feeAmount);
```

```sol
    // transfer strike from putty to exerciser
    ERC20(order.baseAsset).safeTransfer(msg.sender, order.strike);
```

### ■ 修正方法

- `PuttyV2.sol`の498行目のif文の条件を下記に変更する。

```sol
(fee > 0 && order.isCall && isExercised)
```
- putの`exercise()`し、`order.strike`分のトークンを移行した後に再度`feeAmount`を計算するようにする。具体的には下記内容を`PuttyV2.sol`451行目以降に追加

```sol
uint256 feeAmount = 0;
if (fee > 0) {
    feeAmount = (order.strike * fee) / 1000;
    ERC20(order.baseAsset).safeTransfer(owner(), feeAmount);
}
ERC20(order.baseAsset).safeTransfer(msg.sender, order.strike - feeAmount);
```

#### 修正前のコード

1箇所目

```sol
// transfer strike from putty to exerciser
ERC20(order.baseAsset).safeTransfer(msg.sender, order.strike);
```

2箇所目

```sol
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
```

#### 修正後のコード

1箇所目

```sol
// transfer strike from putty to exerciser
uint256 feeAmount = 0;
if (fee > 0) {
    feeAmount = (order.strike * fee) / 1000;
    ERC20(order.baseAsset).safeTransfer(owner(), feeAmount);
}
ERC20(order.baseAsset).safeTransfer(msg.sender, order.strike - feeAmount);
```

2箇所目

```sol
    // transfer strike to owner if put is expired or call is exercised
    if ((order.isCall && isExercised) || (!order.isCall && !isExercised)) {
        // send the fee to the admin/DAO if fee is greater than 0%
        uint256 feeAmount = 0;
        (fee > 0 && order.isCall && isExercised)
            feeAmount = (order.strike * fee) / 1000;
            ERC20(order.baseAsset).safeTransfer(owner(), feeAmount);
        }

        ERC20(order.baseAsset).safeTransfer(msg.sender, order.strike - feeAmount);

        return;
    }
```

## [H-2] acceptcounteroffer()を実行したことにより、2つのorderが満たされる可能性がある脆弱性

### ■ カテゴリー

タイミング

### ■ 条件

すでに`order`が失敗している時に、`cancel()`メソッドを呼び出すこと。

### ■ ハッキングの詳細

ユーザがカウンターオファーを受け入れようとする場合、`acceptCounterOffer()` 関数を、キャンセルされる `originalOrder` と、満たされるべき新しい `order` の両方とともに呼び出します。攻撃者(または同時に`fillOrder()`を呼び出した他のユーザ)は、`acceptCounterOffer()`がキャンセルする前にoriginalOrderを埋めることが可能です。

その結果、originalOrder と order の両方が満たされることになります。`acceptCounterOffer()` の `msg.sender` は、必要なトークン転送が成功すると、意図した結果に加えてさらにもう一回実行します。

```sol
   function acceptCounterOffer(
        Order memory order,
        bytes calldata signature,
        Order memory originalOrder
    ) public payable returns (uint256 positionId) {
        // cancel the original order
        cancel(originalOrder);
        // accept the counter offer
        uint256[] memory floorAssetTokenIds = new uint256[](0);
        positionId = fillOrder(order, signature, floorAssetTokenIds);
    }
```

```sol
    function cancel(Order memory order) public {
        require(msg.sender == order.maker, "Not your order");
        bytes32 orderHash = hashOrder(order);
        // mark the order as cancelled
        cancelledOrders[orderHash] = true;
        emit CancelledOrder(orderHash, order);
    }
```

### ■ 修正方法

すでに`order`が失敗している時は、`cancel()`メソッドが失敗するような条件を加えること

```sol
require(_ownerOf[uint256(orderHash)] == 0)
```

#### 修正前のコード

```sol
    function cancel(Order memory order) public {
        require(msg.sender == order.maker, "Not your order");
        bytes32 orderHash = hashOrder(order);
        // mark the order as cancelled
        cancelledOrders[orderHash] = true;
        emit CancelledOrder(orderHash, order);
    }
```

#### 修正後のコード

```sol
    function cancel(Order memory order) public {
        require(msg.sender == order.maker, "Not your order");
        bytes32 orderHash = hashOrder(order);

        require(_ownerOf[uint256(orderHash)] == 0)
        
        // mark the order as cancelled
        cancelledOrders[orderHash] = true;
        emit CancelledOrder(orderHash, order);
    }
```

## [H-3] 空でないfloorでshort call  オーダーを作成すると、オプションのexerciseやwithdrawが不可能になる脆弱性

### ■ カテゴリー

ERC721

### ■ 条件

- ケース 1: baseが空の `floorAssetTokenIds` 配列で権利行使を呼び出した場合。
- ケース 2: 空ではない `floorAssetTokenIds` 配列 (`orders.floorTokens`の個数と同じであること) を指定して行使を呼び出す場合。
case1では、入力された`floorAssetTokenIds`がput注文で空であることがチェックされ、彼の呼び出しはこの要件をpassしています。しかし、最終的に`_transferFloorsIn`が呼び出され、`Index out of bounds`エラーが発生します。これは`floorTokens`が空ではなく、空のfloorAssetTokenIdsと一致しないためです。

### ■ ハッキングの詳細

`floorTokens` 配列が空でない且つfloorでshort call  オーダーが作成された場合、テイカーは`exercise()`できません。また、満期後にメーカーが引出すこともできません。注文が成立した場合にも、建玉者はプレミアムを獲得することができます。もし、`floorTokens`が空でない配列が偶然含まれていた場合、買い手は行使できずにプレミアムを失い、メーカーもロックされたERC20トークンとERC721トークンを失うという、両者にとっての損失となります。

```sol
    // case 1
    // PuttyV2.sol: _transferFloorsIn called by exercise
    // The floorTokens and floorTokenIds do not match the lenghts
    // floorTokens.length is not zero, while floorTokenIds.length is zero
    ERC721(floorTokens[i]).safeTransferFrom(from, address(this), floorTokenIds[i]);
```

```sol
    // case2
    // PuttyV2.sol: exercise
    // non empty floorAssetTokenIds array is passed for put option, it will revert
    !order.isCall
        ? require(floorAssetTokenIds.length == order.floorTokens.length, "Wrong amount of floor tokenIds")
        : require(floorAssetTokenIds.length == 0, "Invalid floor tokenIds length");
```

### ■ 修正方法

`order()`が呼び出された時に、`fillOder()`メソッドの中で、`order.floorTokens`が空であることを確認するようなロジックを追記すること。

#### 修正前のコード

```sol
    // check floor asset token ids length is 0 unless the order type is call and side is long
    !order.isCall
        ? require(floorAssetTokenIds.length == order.floorTokens.length, "Wrong amount of floor tokenIds")
        : require(floorAssetTokenIds.length == 0, "Invalid floor tokenIds length");
```

#### 修正前のコード

```sol
    // check floor asset token ids length is 0 unless the order type is call and side is long
    !order.isCall
        ? require(floorAssetTokenIds.length == order.floorTokens.length, "Wrong amount of floor tokenIds")
        : require(floorAssetTokenIds.length == 0, "Invalid floor tokenIds length");
    require(order.floorTokens.length == 0, "order.floorTokens.length must be 0");
```

## [H-4] 0 strike call オプションは、買い手からプレミアムを奪うのに使用できてしまう脆弱性

### ■ カテゴリー

Weird ERC20 Tokens

### ■ 条件

送金するトークンの送金量が0であること。

### ■ ハッキングの詳細

現在、このPuttyV2コントラクトでは権利行使価格を確認せず、無条件に`safeTransferFrom`を実行しようとしています。 
しかし、`Weird ERC20 Tokens`に準拠しているトークンでは送金額を0に設定して`transfer`することはできないので、`reverts`が発生します。

```sol
    function exercise(Order memory order, uint256[] calldata floorAssetTokenIds) public payable {
    ...
    if (order.isCall) {
        // -- exercising a call option
        // transfer strike from exerciser to putty
        // handle the case where the taker uses native ETH instead of WETH to pay the strike
        if (weth == order.baseAsset && msg.value > 0) {
            // check enough ETH was sent to cover the strike
            require(msg.value == order.strike, "Incorrect ETH amount sent");
            // convert ETH to WETH
            // we convert the strike ETH to WETH so that the logic in withdraw() works
            // - because withdraw() assumes an ERC20 interface on the base asset.
            IWETH(weth).deposit{value: msg.value}();
        } else {
            ERC20(order.baseAsset).safeTransferFrom(msg.sender, address(this), order.strike);
        }
        // transfer assets from putty to exerciser
        _transferERC20sOut(order.erc20Assets);
        _transferERC721sOut(order.erc721Assets);
        _transferFloorsOut(order.floorTokens, positionFloorAssetTokenIds[uint256(orderHash)]);
    }
```

### ■ 修正方法

送金するトークンの量が0より大きいことを確認するロジックを追記すること。

#### 修正前のコード

```sol
    } else {
        ERC20(order.baseAsset).safeTransferFrom(msg.sender, address(this), order.strike);
    }
```

#### 修正後のコード

```sol
    } else {
        if (order.strike > 0) {
            ERC20(order.baseAsset).safeTransferFrom(msg.sender, address(this), order.strike);
        }
    }
```

## [M-1] 悪意のあるトークンコントラクトが設定されていることでorderをロックする可能性がある脆弱性

### ■ カテゴリー

ERC20、ERC721

### ■ 条件

次のいずれかの変数に悪意あるトークンのアドレスが登録されていた場合に、`exercise()`か`withdraw()`をが呼びだされた場合

- baseAsset
- floorTokens[]
- erc20Assets[]
- erc721Assets[]

### ■ ハッキングの詳細

```sol
bool isLong;
address baseAsset;
```

```sol
address[] floorTokens;
ERC20Asset[] erc20Assets;
```

攻撃者は、注文を作成し、そのアドレスの1つを攻撃者のコントロール下にある悪意のあるコントラクトに設定することができる。攻撃者は、ユーザーが注文を出すのを許可し、その後、悪意のあるコントラクトの変数をトグルして、常にそれを元に戻すようにする。

攻撃者は、注文が好ましくないポジションにある場合（例えば、ショートして価格が上昇した場合）、注文が`exercise()`されるのを防ぐことによって利益を得る。攻撃者は、時間切れか価格が下がるのを待ち、悪意のあるトークンで転送が行われるようにする。

`withdraw()`関数も信頼できない外部アドレスを呼び出すため、同様の攻撃を行うことができます。この場合、攻撃者はオプションを行使し、他のユーザーがNFTまたはERC20トークンを要求できないようにすることができます。

### ■ 修正方法

ERC20かERC721を継承したトークンのみを登録するように承認制で登録するかホワイトリスト化すること。  

例えば次のようなメソッドを実装してowner権限を持つアドレスが承認したトークンの配列を用意するようにする。

```sol
function addApprovedTokens(address _token) private {
    if (msg.sender != owner) revert();
    erc20Assets.push(_token);
  }
```

## [M-２] 無制限ループにより、exercise()とdrawal()のメソッドの実行が失敗しDoSが発生する可能性がある脆弱性

### ■ カテゴリー

DoS

### ■ 条件

`assets.length`と`floorTokens.length`の数がとても大きい場合

### ■ ハッキングの詳細

注文で転送されるトークンの数に制限はなく、ガスの必要量も変わることがあるため（特に注文の期間は27年間）、時間T1に満たされた注文は時間T2には行使/引き出しができないかもしれないし、資産が転送中に多くのガスを使用する場合（例えばaTokensやcTokens）、提供された資産では行使できないかもしれない。オプションの買い手はプレミアムを支払っているのに、借りているアセットを手に入れることができないことになる。

```sol
function _transferERC20sOut(ERC20Asset[] memory assets) internal {
    for (uint256 i = 0; i < assets.length; i++) {
        ERC20(assets[i].token).safeTransfer(msg.sender, assets[i].tokenAmount);
    }
}
```

```sol
function _transferERC721sOut(ERC721Asset[] memory assets) internal {
    for (uint256 i = 0; i < assets.length; i++) {
        ERC721(assets[i].token).safeTransferFrom(address(this), msg.sender, assets[i].tokenId);
    }
}
```

```sol
function _transferFloorsOut(address[] memory floorTokens, uint256[] memory floorTokenIds) internal {
    for (uint256 i = 0; i < floorTokens.length; i++) {
        ERC721(floorTokens[i]).safeTransferFrom(address(this), msg.sender, floorTokenIds[i]);
    }
}
```

### ■ 修正方法

`assets.length`と`floorTokens.length`に設定できる上限値を設置すること。また、その上限値を超えていないかチェックするロジックを入れること。  

まず、上限値として定数を定義する。

```sol
const UPPER_TOKENS =  50;
```

そしてコントラクト内でチェックするロジックを加える。

```sol
function _transferFloorsOut(address[] memory floorTokens, uint256[] memory floorTokenIds) internal {
    // ここにチェックするロジックを加える
    require(floorTokens.length <= UPPER_TOKENS, "floorTokens.length is too much!")

    for (uint256 i = 0; i < floorTokens.length; i++) {
        ERC721(floorTokens[i]).safeTransferFrom(address(this), msg.sender, floorTokenIds[i]);
    }
}
```

## [M-3] プットオプションの売り手が、送金額を0にしたり存在しないトークンを指定することでDoSが発生する脆弱性

### ■ カテゴリー

DoS

### ■ 条件

`order.erc20Assets`にセットされたトークンを送金する際に、送金額が0であるかアドレスに存在しないアドレスを設定された場合に発生する。

### ■ ハッキングの詳細

`PuttyV2.sol`にて次のようにトークンを転送するロジックがあるが、上記条件を満たすとrevertsが発生する。

```sol
_transferERC20sIn(order.erc20Assets, msg.sender);
```

### ■ 修正方法

関数実行時点でそのトークンが存在していないのであれば、`fillOrder()`メソッドで送金するトークンの額とアドレス情報を検証するロジックを加えること。またコントラクトに登録できるアドレスを承認制にすることも検討すること。  

## [M-1] プットオプションの手数料を無料に設定してしまっている脆弱性

### ■ カテゴリー

ERC20

### ■ 条件

プット・オプションの手数料が無料で設定されていること。

### ■ ハッキングの詳細

現在のPuttyV2コントラクトの実装では、`exercise()`されたプット・オプションの手数料を差し引くことができない状態となっている。

```sol
// transfer strike to owner if put is expired or call is exercised
if ((order.isCall && isExercised) || (!order.isCall && !isExercised)) {
    // send the fee to the admin/DAO if fee is greater than 0%
    uint256 feeAmount = 0;
    if (fee > 0) {
        feeAmount = (order.strike * fee) / 1000;
        ERC20(order.baseAsset).safeTransfer(owner(), feeAmount); // @audit DoS due to reverting erc20 token transfer (weird erc20 tokens, blacklisted or paused owner; erc777 hook on owner receiver side can prevent transfer hence reverting and preventing withdrawal) - use pull pattern @high  // @audit zero value token transfers can revert. Small strike prices and low fee can lead to rounding down to 0 - check feeAmount > 0 @high  // @audit should not take fees if renounced owner (zero address) as fees can not be withdrawn @medium
    }
    ERC20(order.baseAsset).safeTransfer(msg.sender, order.strike - feeAmount); // @audit fee should not be paid if strike is simply returned to short owner for expired put @high
    return;
}
```

```sol
// transfer strike from putty to exerciser
ERC20(order.baseAsset).safeTransfer(msg.sender, order.strike);
```

### ■ 修正方法

`exercise()`されたプットオプションに対しても手数料を課すような仕組みに変更すること。

## [M-5] fillorder()とexercise()を実行することにより、コントラクトに送られた資産が凍結されてしまう可能性がある脆弱性

### ■ カテゴリー

ERC20

### ■ 条件

送金するETHの額を0に設定して、`fillOrder()` と `exercise()` を呼び出した場合

### ■ ハッキングの詳細

`fillOrder()` と `exercise()` には Ether を必要とするケースがあり (例: WETH を基本資産として使用、または行使価格の提供)、これら 2 つの関数には `payable` 修飾子が設定されています。しかし、これらの関数内にはEtherを必要としないケースも存在します。ETHを必要としないケースになった場合、関数に渡されたイーサは永遠にコントラクトに固定され、送信者は資金を動かすことができなくなります。

```sol
ERC20(order.baseAsset).safeTransferFrom(order.maker, msg.sender, order.premium);
```

```sol
ERC20(order.baseAsset).safeTransferFrom(msg.sender, order.maker, order.premium);
```

```sol
ERC20(order.baseAsset).safeTransferFrom(msg.sender, address(this), order.strike);
```

### ■ 修正方法

上記メソッドで、トークンを転送するロジックを行う前に、送金するETHの金額が0であることを確認するロジックを入れる。

#### 修正前のコード

```sol
ERC20(order.baseAsset).safeTransferFrom(order.maker, msg.sender, order.premium);
```

#### 修正後のコード

```sol
require(0 == msg.value)
ERC20(order.baseAsset).safeTransferFrom(order.maker, msg.sender, order.premium);
```

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

## [M-7] 攻撃者が(cryptopunkのような)ERC721に準拠していないNFTでshortプットオプションオーダーを作成でき、ユーザーはそのオーダーを満たすことができるが、オプションをexerciseすることができない脆弱性

### ■ カテゴリー

ERC721

### ■ 条件

`baseAsset`にcryptopunkのようなERC721に準拠していないNFTコントラクトのアドレスを設定した場合

### ■ ハッキングの詳細

攻撃者は、cryptopunkを使ってショートプットオプションを作成することができます。ユーザーが注文を実行すると、`baseAsset`がコントラクトに転送されます。

しかし、cryptopunkはERC721をサポートしていないため、`safeTransferFrom`関数呼び出しが失敗し、ユーザーはオプションを`exercise()`することができなくなります。攻撃者はプレミアムを取得し、オプションの期限が切れた後に`baseAsset`を取り戻すことができます。

```sol
if (!order.isLong && !order.isCall) {
    ERC20(order.baseAsset).safeTransferFrom(order.maker, address(this), order.strike);
    return positionId;
}

```

```sol
ERC721(floorTokens[i]).safeTransferFrom(from, address(this), floorTokenIds[i]);
```

### ■ 修正方法

`baseAsset`に設定できるNFTについては、ERC721に準拠したトークンアドレスのみを使用できるようにホワイトリスト化して管理すること。

## [M-8] order.erc20assets または order.baseasset が erc20 でなく erc721 になる可能がある脆弱性。

### ■ カテゴリー

ERC20, ERC721

### ■ 条件

`baseAsset` や `erc20Assets`にセットされているコントラクトアドレス が ERC20 ではなく ERC721 アドレスとして処理されてしまった場合

### ■ ハッキングの詳細

ERC20とERC721の`transferFrom()`は両方とも同じメソッドIDを持っています。  
この影響により、`baseAsset` や `erc20Assets` が ERC20 ではなく ERC721 アドレスになる可能性があります。

これらの関数は、NFTをプロトコルに正常に転送しますが、NFTをコントラクトの外に転送することには失敗します。これは、転送用のメソッドが `ERC20.safeTransfer()` で `transfer(to, amount)` を呼び出すためで、ERC721 の有効な関数のメソッドIDと一致しないためです。

したがって、この方法で`fillOrder()`を使ってコントラクトに転送されたERC721トークンは、`exercise()`や`withdraw()`がコントラクトからトークンをうまく転送できないため、永久にその中に留まってしまうことになります。

```sol
ERC20(order.baseAsset).safeTransferFrom(order.maker, msg.sender, order.premium);
```

```sol
ERC20(token).safeTransferFrom(from, address(this), tokenAmount);
```

### ■ 修正方法

PuttyV2コントラクト内で使用するERC721とERC20のトークンアドレス情報をホワイトリスト化して管理する。またそのホワイトリストをERC20用とERC721用に分けて管理すること。

## [M-9] コントラクトが、手数料なしのフラッシュローンプールとして機能する脆弱性

### ■ カテゴリー

Flash Loan

### ■ 条件

ローンの作成者とテイカーが同じアドレスである場合。

### ■ ハッキングの詳細

悪意のあるユーザは、PuttyV2コントラクトを利用して、資産に手数料を支払うことなくフラッシュローンを行い、利益を得ることができます。

```sol
ERC20(order.baseAsset).safeTransferFrom(order.maker, msg.sender, order.premium);
```

コントラクトは、標準のERC20以外のカスタムロジックを持つコントラクトを`order.baseAssets`で参照したロングコール注文でPuttyV2.fillOrderを呼び出します。この注文では、PuttyV2のコントラクトが負っているトークンとtokenAmountにerc20Assetsも指定します（erc721Assetsと同様）。  

実行するメソッドが上記のコードであるとき、カスタムロジックは、コントラクトアドレス `order.baseAsset` で実行することができます。
その後、悪意のある契約は、ショートコールのポジションを行使するために、行使を呼び出します。このコールにより、`_transferERC20sOut`、`_transferERC721sOut`のロジックが実行され、注文で指定された資産が悪意のあるコントラクトに移管されます。  

この契約は、その資産を他のプラットフォームで利益を上げるために使用します。その後、上記のコード実行されます。
`fillOrder()`が終了すると、契約は実行を終了するために`_transferERC20sIn`, `_transferERC721sIn`で論理を実行することによって、PuttyV2に十分な資産を転送することができます。

### ■ 修正方法

`exercise()`メソッド内で、`order.baseAssets`トークンを移転せずに、移転の記録にはmapping変数を利用して送信先のアドレス情報を管理するようにすること。  

その上で`redeem`という`external`修飾子をつけたメソッドを作成し、その中で`transfer`を実行すること。

```sol
mapping(uint => address) public loanOwners;
```

```sol
function redeem(Order order) external {
    // transfer
    ERC20(order.baseAsset).safeTransferFrom(order.maker, msg.sender, order.premium);
}
```

## [M-10] Puttyポジショントークンは、erc721に準拠していないアドレス宛にミントされてしまう可能性がある脆弱性

### ■ カテゴリー

ERC721

### ■ 条件

NFTのミント先のアドレスにERC721準拠対応のコントラクトアドレス以外の値が設定された場合

### ■ ハッキングの詳細

Puttyはコードベース全体でERC721 safeTransferとsafeTransferFromを使用して、ERC721トークンがERC721以外の受信機に転送されないようにしています。しかし、fillOrderの最初の位置の`mint`は`_safeMint`ではなく`_mint`を使用し、Receiverに設定されたアドレスがERC721に対応しているアドレス化どうか確認していないために凍結してしまう可能性があります。

```sol
// create long/short position for maker
_mint(order.maker, uint256(orderHash));

// create opposite long/short position for taker
bytes32 oppositeOrderHash = hashOppositeOrder(order);
positionId = uint256(oppositeOrderHash);
_mint(msg.sender, positionId);
```

```sol
function _mint(address to, uint256 id) internal override {
    require(to != address(0), "INVALID_RECIPIENT");
    require(_ownerOf[id] == address(0), "ALREADY_MINTED");

    _ownerOf[id] = to;

    emit Transfer(address(0), to, id);
}
```

### ■ 修正方法

Solmateの `ERC721#_safeMint`メソッドの中に次のようなrequire文を加えること

#### 修正前のコード

```sol
function _safeMint(address to, uint256 id) internal virtual {
    _mint(to, id);
}
```

#### 修正後のコード

```sol
function _safeMint(address to, uint256 id) internal virtual {
    _mint(to, id);
    require(
        to.code.length == 0 ||
            ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
            ERC721TokenReceiver.onERC721Received.selector,
        "UNSAFE_RECIPIENT"
    );
}
```

## [M-11] ユーザーの同意なしに手数料を変更することができる脆弱性

### ■ カテゴリー

タイミング

### ■ 条件

注文が成立してから出金までに時間がかかってしまう場合

### ■ ハッキングの詳細

手数料は出金時に適用されますが、注文が成立し、その条件が合意されてから出金までの間に変更されることがあり、当該利用者が期待した資金が失われる可能性がある。

```sol
function setFee(uint256 _fee) public payable onlyOwner {
    require(_fee < 30, "fee must be less than 3%");

    fee = _fee;

    emit NewFee(_fee);
}
```

```sol
uint256 feeAmount = 0;
```

### ■ 修正方法

- 手数料をOrderに格納し、注文が満たされたときに手数料が正しいかどうかを検証する。
- タイムスタンプの追加
- 過去の手数料と手数料変更のタイムスタンプをメモリに保持し（例えば配列で）、出金時に作成時の手数料を取得できるようにする。

## [M-12] 権利行使価格の小さいオプションは0に切り捨てられ、資産の引き出しができなくなる可能性がある脆弱性

### ■ カテゴリー

ERC20

### ■ 条件

`fee`がかなり小さい値にセットされている場合

### ■ ハッキングの詳細

特定のERC-20トークンは、総金額0のトークンの転送と復帰をサポートしていません。そのようなトークンを、かなり小さなオプション行使と低いプロトコル手数料率の`order.baseAsset`として使用すると、0に切り捨てられ、それらのポジションの資産の引き出しができなくなる可能性があります。

```sol
feeAmount = (order.strike * fee) / 1000;
ERC20(order.baseAsset).safeTransfer(owner(), feeAmount);
``` 

### ■ 修正方法

総金額が0より大きいことをチェックするロジックを加えること

#### 修正前のコード

```sol
// send the fee to the admin/DAO if fee is greater than 0%
uint256 feeAmount = 0;
if (fee > 0) {
    feeAmount = (order.strike * fee) / 1000;
    ERC20(order.baseAsset).safeTransfer(owner(), feeAmount);
}
```

#### 修正後のコード

```sol
// send the fee to the admin/DAO if fee is greater than 0%
uint256 feeAmount = 0;
if (fee > 0) {
    feeAmount = (order.strike * fee) / 1000;
    if (feeAmount > 0) {
        ERC20(order.baseAsset).safeTransfer(owner(), feeAmount);
    }
}
```

## [M-12] 権利行使価格の小さいオプションは0に切り捨てられ、資産の引き出しができなくなる可能性がある脆弱性

### ■ カテゴリー

ERC20

### ■ 条件

`fee`がかなり小さい値にセットされている場合

### ■ ハッキングの詳細

特定のERC-20トークンは、総金額0のトークンの転送と復帰をサポートしていません。そのようなトークンを、かなり小さなオプション行使と低いプロトコル手数料率の`order.baseAsset`として使用すると、0に切り捨てられ、それらのポジションの資産の引き出しができなくなる可能性があります。

```sol
feeAmount = (order.strike * fee) / 1000;
ERC20(order.baseAsset).safeTransfer(owner(), feeAmount);
``` 

### ■ 修正方法

総金額が0より大きいことをチェックするロジックを加えること

#### 修正前のコード

```sol
// send the fee to the admin/DAO if fee is greater than 0%
uint256 feeAmount = 0;
if (fee > 0) {
    feeAmount = (order.strike * fee) / 1000;
    ERC20(order.baseAsset).safeTransfer(owner(), feeAmount);
}
```

#### 修正後のコード

```sol
// send the fee to the admin/DAO if fee is greater than 0%
uint256 feeAmount = 0;
if (fee > 0) {
    feeAmount = (order.strike * fee) / 1000;
    if (feeAmount > 0) {
        ERC20(order.baseAsset).safeTransfer(owner(), feeAmount);
    }
}
```

## [M-14] 注文の取り消しはフロントランニングになりやすく、中央集権的なデータベースに依存する脆弱性

### ■ カテゴリー

FrontRunning

### ■ 条件

悪意あるメーカーが関数パラメータとして注文を入力し、`cancel()`を呼び出してFrontRunngingの脆弱性を突いた場合

### ■ ハッキングの詳細

注文のキャンセルは、メーカーが関数パラメータとして注文を入力し、`cancel()`を呼び出す必要があります。これは唯一のキャンセル方法であり、2つの問題を引き起こす可能性があります。

- 最初の問題は、MEV ユーザーがキャンセルをFrontRunngingし、注文を満たすためのオンチェーンシグナルであることです。

- 2つ目の問題は、注文をキャンセルするために中央集権的なサービスに依存することです。注文はオフチェーンで署名されるので、中央のデータベースに保存されることになります。エンドユーザーが、自分が出した注文をすべてローカルに記録することは、まずないでしょう。つまり、注文をキャンセルする場合、メーカーは集中型サービスに注文パラメータを要求する必要があります。もし、集中管理サービスがオフラインになった場合、注文データベースのコピーを持つ悪意のある者が、他の方法ではキャンセルされたはずの注文を満たすことができるようになる可能性があります。

### ■ 修正方法

今ある注文をキャンセルする方法とは別に呼び出し元のすべてのオーダーをキャンセルする追加メソッドを実装すること。  
そのために次のようなmapping変数を追加する。

```sol
mapping(address => uint256) minimumValidNonce;
```

## [M-15] ゼロストライクコールオプションはシステム手数料の支払いを回避することができる脆弱性

### ■ カテゴリー

ERC20

### ■ 条件

オーダーにセットされる`order.strike`の値が0または0に限りなく近い値にセットされた場合。

### ■ ハッキングの詳細

ゼロまたはゼロに近い権利行使価格のコールは、一般的なデリバティブの一種です。このようなデリバティブでは、手数料が権利行使価格の何分の一かであるため、システムは手数料を受け取ることができません。  

また、OTMのコールオプションの場合、オプションそのものはほとんど価値がないのに、権利行使価格が大きくなるため、手数料が大きくなってしまうという問題があります。例えば、1kのETH BAYCコールはあまり価値がありませんが、それを正当化するものは何もないのに、関連する手数料は通常の手数料の10倍、すなわちかなりのものになります。  

```sol
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
```

### ■ 修正方法

feeは、簡単に操作できないオプション価値であり、システムの取引量に正確に対応するため、オプションプレミアムと連動させるようにして簡単に操作できないようにする。

## [M-6] puttyv2に適用される2つの既知の問題があるsolidityバージョン0.8.13を使用する。

### ■ カテゴリー

Solidity version 

### ■ 条件

Solidity version 0.8.13を利用している場合

### ■ ハッキングの詳細

solidity version 0.8.13 には、`PuttyV2コントラクト` に該当する以下の2つの問題があります。

- ABI-encodingに関する脆弱性。

ref : https://blog.soliditylang.org/2022/05/18/solidity-0.8.14-release-announcement/  
hashOrder(), hashOppositeOrder() 関数に適用条件があるため、本脆弱性を悪用される可能性があります。  
"...ネストした配列を直接別の外部関数呼び出しに渡すか、それに対してabi.encodeを使用する。"

- インラインアセンブリのメモリ副作用に関する最適化の際のバグに関連する脆弱性  

ref : https://blog.soliditylang.org/2022/06/15/solidity-0.8.15-release-announcement/  
`PuttyV2`はopenzeppelinとsolmateのsolidityコントラクトを継承しており、どちらもインラインアセンブリを使用しており、コンパイル時に最適化が行われるようになっています。

### ■ 修正方法

Solidity version 0.8.15を利用する。