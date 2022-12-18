# メモ

## Caviarとは

Caviarは完全なオンチェーンNFT AMMで、コレクション内のすべてのNFT（フロアからスーパーレアまで）を取引することが可能です。また、各NFTの端数の取引も可能です。
合成可能性、柔軟性、使いやすさに重点を置いて設計されています。

### setApproveForAllが怪しそう

### Earn a 0.3% fee on all trades by depositing NFTs and ETH into the pool - allowing traders to buy and sell.

# セキュリティの考慮

- リベース/フィーオントランスファートークン
Rebaseおよびfee-on-transferトークンはAMMでサポートされていません。
これらのトークンを使用すると、スワップ曲線と流動性の計算が崩れます。

- スタックしたトークン/nfts
AMMに誤って転送されたトークンの回復メカニズムは存在しません。
トークンまたはNFTが誤ってコントラクトに送信された場合、それらを引き出すことはできません。

- 悪意のあるベーストークンまたはNFTコントラクト
新しいペアを作成するために使用されるすべてのNFTとベーストークンコントラクトは正直であると仮定されています。
ユーザーは、特定のペア契約とやり取りするかどうかを決定する際に、自分の判断で、NFTとベーストークンコントラクトが誠実であることを確認する必要があります。

- 信頼できる管理者
管理者がペアからNFTを引き出すことができる機能が存在します。
管理者が信頼できる正当な人物であることが前提です。しかし、追加の予防措置として、実際に引き出す前に管理者が引き出す意思を示さなければならない1週間の猶予期間があります。
これにより、LPとトレーダーは、管理者よりも先に契約からNFTを引き出すことができます。

# 特徴

Caviarは、スワップ曲線にxy=k不変量を使用したNFT AMMです。ユーザーは、共有流動性プール（ペア）を作成し、そのペアで取引できる特定のNFTに制約を加えることができます。市場で同じように評価されているNFTのグループとペアを作成することは理にかなっています。例えば、フロアNFTを取引するペアやレアNFTを取引するペアなどです。さらに、各ペアには、その中に含まれるNFTの分数ERC20表現も含まれます。ユーザーは、ペアに含まれる有効なNFTを使って、このフラクショナルERC20トークンをラップインおよびラップアウトすることができます。

## Factory (Caviar.sol)

ファクトリー契約は、新しいペアを作成する役割を担っています。ユーザーは、与えられたnft、ベーストークン、およびmerkleルートに対して新しいペアを作成することができます。merkleルートは、特定のペアで取引可能なすべての有効なトークンIDのハッシュです。新しいペアが作成されると、そのアドレスがマッピングに保存されます。管理者は、ペアを破棄することで、このマッピングからペアを削除することができます。

## Pair

Pair.solのロジックは、3つの明確な論理部分に分かれています。コアAMM、NFTラッピング、そしてNFT AMMそのものです。コアAMMはUNI-V2を簡略化したもので、ベーストークン（WETHやUSDCなど）とフラクショナルNFTトークン間のスワッピングを処理します。NFTラッピングロジックにより、NFTをラッピングしてERC20フラクショナルトークンを受け取る、またはその逆が可能です。NFT AMMロジックは、コアAMMとNFTラッピングロジックをラップするヘルパー関数のセットです。

さらに、管理者がペアを閉じるために使用する緊急終了ロジック関数のセットも用意されています。

## Core AMM

流動性供給者は、ベーストークンとERC20フラクショナルトークンを一定量預けることで流動性を追加することができます。その見返りとして、彼らはプール内の流動性のシェアを表すLPトークンをいくらか鋳造されます。

また、LPトークンを燃やすことで、ベーストークンやフラクショナルトークンを取り除くこともできます。

トレーダーは、ベーストークンの量を送信することでプールから購入することができます。その代わり、ERC20の端数トークンを受け取ることができます。

トレーダーは、端数トークンの量を送信することにより、プールから販売することができます。その見返りとして、彼らはベーストークンを受け取ります。

トレーダーは、売買のたびに30bps（0.3%）の手数料を支払います。この手数料は流動性プロバイダーに支払われ、流動性を預けるインセンティブとして機能する。

## NFT Wrapping

ユーザーはNFTをラッピングし、ERC20トークンを受け取ることができます。ラップされた各NFTに対して、1e18トークンが鋳造されます。NFTをラップする際には、各トークンIDがペアのmerkle rootに存在することを検証するmerkle proofも提出する必要があります。

ユーザーは分数ERC20トークンを燃やすことでラッピングを解除することができます。その代わり、ユーザーは契約からN個のNFTを受け取ることになります。

## ANFT AMM

流動性プロバイダーは、自社のNFTとベーストークンを流動性として追加することができます。彼らはLPを希望するトークンIDを指定し、特定のtokenIdsがそのペアのmerkle rootに存在することを示すmerkle証明のセットを提供します。その見返りとして、LPトークンを鋳造することができます。

また、LPトークンを燃やすことで、プールからNFTとベーストークンを取り除くこともできます。

トレーダーはプールからNFTを購入します。購入したいtokenIdsを指定し、適切な量のベーストークンを送信して支払います。

トレーダーはNFTをプールに売却することができます。NFTを売却する際には、売却する各TokenIdがペアのmerkle rootに存在することを示すmerkle証明のセットも提供する必要があります。その見返りとして、トレーダーはいくらかのベーストークンを受け取ります。

## 非常ロジック

NFTの離散的な性質と、全額を送金することしかできないことから、流動性が閉じ込められるか、「グリーフ」されるエッジケースが考えられます。  

グリーフ→何かをなくしたことによって引き起こされる反応  

アリスが1NFTと200USDCをプールに預けた場合を考えてみましょう。次にボブはプールから0.000001の端数のトークンを購入し、それをゼロのアドレスに送ります。このとき、プールには0.999999の端数トークン、200USDC、そして1NFTが存在します。0.9999999の端数トークンしか存在しないため、そのNFTは効率的に動かなくなります。つまり、ラップを解くことは不可能なのです。このような状況が発生した場合、NFTを引き出して、端数トークン保有者全員をどうにかして丸く収める方法が必要です。

私たちが採用している解決策は、次のようなものです。

LPは、プールがグリーフされていると管理者にクレームをつけます。

管理者は、その主張が正当なものかどうかを判断します。

管理者はそのペアを「クローズ」し、今後のラップを防ぎます(他のアクションはすべて有効です)。ペアはファクトリーマッピングからも削除されます (destroy() による)。1 週間の猶予期間がある。

1週間後、管理者は契約中のNFTを引き出し、オークションに出します。オークションの収益は端数トークン所有者に比例配分され、トークンを交換で燃やすことができます。

この流れに関連して、2つの機能があります。

### fraction nft

フラクショナルNFTとは、複数のパーツに分割できるNFTのことです。フラクショナルNFTトークンを購入すると、NFTのシェアがもらえます。例えば、0.1 NFTや0.01 NFTを購入することができます。1枚の端数トークンは1NFTに交換できます。

### テスト結果

```bash
[⠰] Compiling...
[⠔] Compiling 51 files with 0.8.17
[⠊] Solc 0.8.17 finished in 14.36s
Compiler run successful

Running 8 tests for test/Pair/unit/Close.t.sol:CloseTest
[PASS] testCannotExitIfNotAdmin() (gas: 17042)
[PASS] testCannotWithdrawIfNotAdmin() (gas: 42550)
[PASS] testCannotWithdrawIfNotClosed() (gas: 15916)
[PASS] testCannotWithdrawIfNotEnoughTimeElapsed() (gas: 42462)
[PASS] testExitSetsCloseTimestamp() (gas: 38737)
[PASS] testItEmitsCloseEvent() (gas: 41646)
[PASS] testItEmitsWithdrawEvent() (gas: 74205)
[PASS] testItTransfersNftsAfterWithdraw() (gas: 73992)
Test result: ok. 8 passed; 0 failed; finished in 3.73ms

Running 5 tests for test/Pair/unit/NftBuy.t.sol:NftBuyTest
[PASS] testItBurnsFractionalTokens() (gas: 121685)
[PASS] testItReturnsInputAmount() (gas: 119660)
[PASS] testItRevertsSlippageOnBuy() (gas: 31147)
[PASS] testItTransfersBaseTokens() (gas: 126339)
[PASS] testItTransfersNfts() (gas: 125987)
Test result: ok. 5 passed; 0 failed; finished in 5.13ms

Running 9 tests for test/Pair/unit/Buy.t.sol:BuyTest
[PASS] testItEmitsBuyEvent() (gas: 59482)
[PASS] testItRefundsSurplusEther() (gas: 59269)
[PASS] testItReturnsInputAmount() (gas: 55153)
[PASS] testItRevertsIfMaxInputAmountIsNotEqualToValue() (gas: 19683)
[PASS] testItRevertsIfValueIsGreaterThanZeroAndBaseTokenIsNot0() (gas: 19487)
[PASS] testItRevertsSlippageOnBuy() (gas: 24027)
[PASS] testItTransfersBaseTokens() (gas: 61854)
[PASS] testItTransfersEther() (gas: 49067)
[PASS] testItTransfersFractionalTokens() (gas: 59949)
Test result: ok. 9 passed; 0 failed; finished in 6.05ms

Running 6 tests for test/Pair/unit/NftRemove.t.sol:NftRemoveTest
[PASS] testItBurnsLpTokens() (gas: 168475)
[PASS] testItReturnsBaseTokenAmountAndFractionalTokenAmount() (gas: 162712)
[PASS] testItRevertsBaseTokenSlippage() (gas: 38011)
[PASS] testItRevertsNftSlippage() (gas: 63303)
[PASS] testItTransfersBaseTokens() (gas: 168874)
[PASS] testItTransfersNfts() (gas: 168657)
Test result: ok. 6 passed; 0 failed; finished in 4.92ms

Running 4 tests for test/Caviar/Destroy.t.sol:DestroyTest
[PASS] testItEmitsDestroyEvent() (gas: 15598)
[PASS] testItRemovesPairFromMapping() (gas: 14837)
[PASS] testItRemovesPairFromMapping(address,address,bytes32,address) (runs: 256, μ: 188728, ~: 188654)
[PASS] testOnlyPairCanRemoveItself() (gas: 10950)
Test result: ok. 4 passed; 0 failed; finished in 104.91ms

Running 1 test for test/Pair/integration/BuySell.t.sol:BuySellTest
[PASS] testItBuysSellsEqualAmounts(uint256) (runs: 256, μ: 215013, ~: 215036)
Test result: ok. 1 passed; 0 failed; finished in 120.35ms

Running 6 tests for test/Caviar/Create.t.sol:CreateTest
[PASS] testItEmitsCreateEvent() (gas: 3428225)
[PASS] testItReturnsPair() (gas: 3423539)
[PASS] testItRevertsIfDeployingSamePairTwice() (gas: 3427768)
[PASS] testItSavesPair() (gas: 3424943)
[PASS] testItSavesPair(address,address,bytes32) (runs: 256, μ: 3460167, ~: 3479767)
[PASS] testItSetsSymbolsAndNames() (gas: 3490585)
Test result: ok. 6 passed; 0 failed; finished in 183.91ms

Running 3 tests for test/Pair/unit/Unwrap.t.sol:UnwrapTest
[PASS] testItBurnsFractionalTokens() (gas: 116987)
[PASS] testItEmitsUnwrapEvent() (gas: 119213)
[PASS] testItTransfersTokens() (gas: 121757)
Test result: ok. 3 passed; 0 failed; finished in 3.28ms

Running 9 tests for test/Pair/unit/Remove.t.sol:RemoveTest
[PASS] testItBurnsLpTokens() (gas: 101668)
[PASS] testItEmitsRemoveEvent() (gas: 99891)
[PASS] testItReturnsBaseTokenAmountAndFractionalTokenAmount() (gas: 95673)
[PASS] testItReturnsBaseTokenAmountAndFractionalTokenAmount(uint256) (runs: 256, μ: 70573, ~: 51028)
[PASS] testItRevertsBaseTokenSlippage() (gas: 28554)
[PASS] testItRevertsFractionalTokenSlippage() (gas: 28547)
[PASS] testItTransfersBaseTokens() (gas: 102045)
[PASS] testItTransfersEther() (gas: 69915)
[PASS] testItTransfersFractionalTokens() (gas: 100145)
Test result: ok. 9 passed; 0 failed; finished in 43.33ms

Running 6 tests for test/Pair/unit/Sell.t.sol:SellTest
[PASS] testItEmitsSellEvent() (gas: 57075)
[PASS] testItReturnsOutputAmount() (gas: 52778)
[PASS] testItRevertsSlippageOnSell() (gas: 24013)
[PASS] testItTransfersBaseTokens() (gas: 59463)
[PASS] testItTransfersEther() (gas: 27324)
[PASS] testItTransfersFractionalTokens() (gas: 57529)
Test result: ok. 6 passed; 0 failed; finished in 5.65ms

Running 1 test for test/Pair/unit/Price.t.sol:PriceTest
[PASS] testItReturnsCorrectPrice() (gas: 285519)
Test result: ok. 1 passed; 0 failed; finished in 3.03ms

Running 1 test for test/Pair/integration/AddBuySellRemove.t.sol:AddBuySellRemoveTest
[PASS] testItAddsBuysSellsRemovesCorrectAmount(uint256,uint256,uint256) (runs: 256, μ: 786272, ~: 786301)
Test result: ok. 1 passed; 0 failed; finished in 428.00ms

Running 4 tests for test/Pair/unit/Wrap.t.sol:WrapTest
[PASS] testItAddsWithMerkleProof() (gas: 4257698)
[PASS] testItEmitsWrapEvent() (gas: 171295)
[PASS] testItMintsFractionalTokens() (gas: 166988)
[PASS] testItTransfersTokens() (gas: 174567)
Test result: ok. 4 passed; 0 failed; finished in 2.26s

Running 6 tests for test/Pair/unit/NftSell.t.sol:NftSellTest
[PASS] testItMintsFractionalTokens() (gas: 177412)
[PASS] testItReturnsOutputAmount() (gas: 172885)
[PASS] testItRevertsSlippageOnSell() (gas: 163957)
[PASS] testItSellsWithMerkleProof() (gas: 4573729)
[PASS] testItTransfersBaseTokens() (gas: 179587)
[PASS] testItTransfersNfts() (gas: 182645)
Test result: ok. 6 passed; 0 failed; finished in 2.44s

Running 14 tests for test/Pair/unit/Add.t.sol:AddTest
[PASS] testItEmitsAddEvent() (gas: 125360)
[PASS] testItInitMintsLpTokensToSender() (gas: 124930)
[PASS] testItInitMintsLpTokensToSender(uint256,uint256) (runs: 256, μ: 379216, ~: 379224)
[PASS] testItMintsLpTokensAfterInit() (gas: 549141)
[PASS] testItMintsLpTokensAfterInit(uint256,uint256) (runs: 256, μ: 806744, ~: 806747)
[PASS] testItMintsLpTokensAfterInitWithEther() (gas: 319611)
[PASS] testItRevertsIfAmountIsZero() (gas: 14256)
[PASS] testItRevertsIfValueDoesNotMatchBaseTokenAmount() (gas: 27280)
[PASS] testItRevertsIfValueIsNot0AndBaseTokenIsNot0() (gas: 27056)
[PASS] testItRevertsSlippageAfterInitMint() (gas: 133851)
[PASS] testItRevertsSlippageOnInitMint() (gas: 20342)
[PASS] testItTransfersBaseTokens() (gas: 126255)
[PASS] testItTransfersEther() (gas: 98122)
[PASS] testItTransfersFractionalTokens() (gas: 124375)
Test result: ok. 14 passed; 0 failed; finished in 2.46s

Running 7 tests for test/Pair/unit/NftAdd.t.sol:NftAddTest
[PASS] testItAddsWithMerkleProof() (gas: 4367176)
[PASS] testItInitMintsLpTokensToSender() (gas: 262210)
[PASS] testItMintsLpTokensAfterInit() (gas: 854116)
[PASS] testItRevertsSlippageAfterInitMint() (gas: 466678)
[PASS] testItRevertsSlippageOnInitMint() (gas: 177509)
[PASS] testItTransfersBaseTokens() (gas: 263563)
[PASS] testItTransfersNfts() (gas: 267865)
Test result: ok. 7 passed; 0 failed; finished in 2.34s
```