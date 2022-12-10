# Backed Protocol contest Findings & Analysis Report

## 今回監査の対象となるPutty V2の概要

NFTとERC20のオーダーブックプロダクト。  
オーダーブックを作成する方法オフチェーンで4通りあり、NFTとしてコントラクトが発行される。  

balanceOfメソッドを取り除いている。  

**注意事項**  

**フロアオプション**  
コードの中で、おそらく直感的に理解できない部分が1つあります。それは、floorTokenIds と positionFloorAssetTokenIds です。これは、フロア NFT オプションをサポートするための方法です。

このアイデアは、アリスが3つのfloorToken (address[])でプットオプションを作成し、ボブが行使したいときに、floorTokensにリストされているコレクションから任意の3つのトークンを送信できるようにすることです。彼はコレクションから任意のトークンを使うことができるので、これは実質的にフロアオプションの複製であり、行使するとき、彼は常に最も低い値のトークン - フロアを選択します。  

同様にアリスは、5つのfloorToken (address[])を使ってロングコールオプションのオフチェーン注文を作ることができる。ボブはこの注文を満たし(fillOrder)、floorTokensにリストされているコレクションから任意の5つのトークン(floorTokenIds)を担保として送ることができる。  

行使または fillOrder が発生すると、ボブが使用した floorTokenIds を positionFloorAssetTokenIds に保存します。これは、次のような状況で、後でそれらを参照できるようにするためです。  

- a) Bobがプット・オプションを行使した。アリスはそのとき、ボブが使用したフロア・トークンを引き出すことができる。

- b) アリスがロングコールオプションを行使した。フロアトークはアリスに送られる。

- c) アリスは自分のロングコールオプションを失効させた。フロアトークはBobに送り返される。

**リベーストークンとフィーオントランスファートークン**  
ユーザーの残高が時間とともに更新される方法について、カスタム実装を持つさまざまなトークンがあります。最も一般的なのは、fee-on-transferトークンとrebaseトークンです。永続的な会計処理は複雑でコストがかかるため、私たちはこれらのトークンをサポートするつもりはありません。

**ウォーデンに関する懸念事項**  
コードには、物事が正しく行われているという確信が持てない場所がいくつかあります。これらは、潜在的に低空飛行の果実として機能する可能性があります。

- 不正確なEIP-712の実装
- トークン転送による外部コントラクト呼び出しがリエントランシーにつながる
- fillOrderとexerciseにおけるWETHへのネイティブETHの不正な処理
- タイムスタンプの操作

### ハイリスクの脆弱性

- [H-01] FEE IS BEING DEDUCTED WHEN PUT IS EXPIRED AND NOT WHEN IT IS EXERCISED.
- [H-02] ACCEPTCOUNTEROFFER() MAY RESULT IN BOTH ORDERS BEING FILLED
- [H-03] CREATE A SHORT CALL ORDER WITH NON EMPTY FLOOR MAKES THE OPTION IMPOSSIBLE TO EXERCISE AND WITHDRAW
- [H-04] ZERO STRIKE CALL OPTIONS CAN BE SYSTEMICALLY USED TO STEAL PREMIUM FROM THE TAKER


- [h-01] 手数料は、プットが行使されたときではなく、期限切れになったときに差し引かれます。
- [H-02] acceptcounteroffer()は両方の注文が満たされる結果になることがあります。
- [H-03] 空でないフロアでショートコール注文を作成すると、オプションの行使や引き出しが不可能になる。
- [H-04] ゼロストライクコールオプションは、買い手からプレミアムを奪うためにシステム的に使用できる。

### ミドルリスクの脆弱性

- [M-01] MALICIOUS TOKEN CONTRACTS MAY LEAD TO LOCKING ORDERS
- [M-02] UNBOUNDED LOOPS MAY CAUSE EXERCISE()S AND WITHDRAW()S TO FAIL
- [M-03] PUT OPTION SELLERS CAN PREVENT EXERCISE BY SPECIFYING ZERO AMOUNTS, OR NON-EXISTANT TOKENS
- [M-04] PUT OPTIONS ARE FREE OF ANY FEES
- [M-05] FILLORDER() AND EXERCISE() MAY LOCK ETHER SENT TO THE CONTRACT, FOREVER
- [M-06] [DENIAL-OF-SERVICE] CONTRACT OWNER COULD BLOCK USERS FROM WITHDRAWING THEIR STRIKE
- [M-07] AN ATTACKER CAN CREATE A SHORT PUT OPTION ORDER ON AN NFT THAT DOES NOT SUPPORT ERC721 (LIKE CRYPTOPUNK), AND THE USER CAN FULFILL THE ORDER, BUT CANNOT EXERCISE THE OPTION
- [M-08] OVERLAP BETWEEN ERC721.TRANSFERFROM() AND ERC20.TRANSFERFROM() ALLOWS ORDER.ERC20ASSETS OR ORDER.BASEASSET TO BE ERC721 RATHER THAN ERC20
- [M-09] THE CONTRACT SERVES AS A FLASHLOAN POOL WITHOUT FEE
- [M-10] PUTTY POSITION TOKENS MAY BE MINTED TO NON ERC721 RECEIVERS
- [M-11] FEE CAN CHANGE WITHOUT THE CONSENT OF USERS
- [M-12] OPTIONS WITH A SMALL STRIKE PRICE WILL ROUND DOWN TO 0 AND CAN PREVENT ASSETS TO BE WITHDRAWN
- [M-13] ORDER DURATION CAN BE SET TO 0 BY MALICIOUS MAKER
- [M-14] ORDER CANCELLATION IS PRONE TO FRONTRUNNING AND IS DEPENDENT ON A CENTRALIZED DATABASE
- [M-15] ZERO STRIKE CALL OPTIONS WILL AVOID PAYING SYSTEM FEE
- [M-16] USE OF SOLIDITY VERSION 0.8.13 WHICH HAS TWO KNOWN ISSUES APPLICABLE TO PUTTYV2

- [m-01] 悪意のあるトークンコントラクトがロック注文につながる可能性がある。
- [m-02] 無制限ループはexercise()とdrawal()を失敗させる可能性がある。
- [m-03] プットオプションの売り手は、ゼロ金額や存在しないトークンを指定することで行使を阻止することができる。
- [m-04] プットオプションの手数料は無料です。
- [m-05] fillorder()とexercise()はコントラクトに送られたエーテルを永遠にロックする可能性がある。
- [m-06] [サービス拒否] 契約の所有者はユーザがストライクを撤回するのをブロックすることができる
- [m-07] 攻撃者が(cryptopunkのような)erc721をサポートしないnft上でショートプットオプションオーダーを作成でき、ユーザーはそのオーダーを満たすことができるが、オプションを行使することができない。
- [m-08] erc721.transferfrom() と erc20.transferfrom() の間の重複は、order.erc20assets または order.baseasset が erc20 でなく erc721 になることを可能にする。
- [M-09] 契約は、手数料なしのフラッシュローンプールとして機能する。
- [m-10] パティポジショントークンは、erc721以外のレシーバに鋳造されるかもしれない。
- [m-11] ユーザーの同意なしに手数料を変更することができる。
- [m-12] 権利行使価格の小さいオプションは0に切り捨てられ、資産の引き出しができなくなる可能性がある
- [m-13]悪意のあるメーカーが注文期間を0に設定することができる。
- [m-14]注文の取り消しはフロントランニングになりやすく、中央集権的なデータベースに依存する。
- [m-15] ゼロストライクコールオプションはシステム手数料の支払いを回避することができる。
- [m-16] puttyv2に適用される2つの既知の問題があるsolidityバージョン0.8.13を使用する。
