# SolidityLearing
Solidityの細かい仕様まで学習するためのリポジトリ

### Visibility
Functions can be declared as

- public - any contract and account can call
- private - only inside the contract that defines the function
- internal- only inside contract that inherits an internal function
- external - only other contracts and accounts can call

### receive()とfallback()の違い

How to receive Ether?
A contract receiving Ether must have at least one of the functions below

- receive() external payable
- fallback() external payable
receive() is called if msg.data is empty, otherwise fallback() is called.  

receive()はトランザクションのインプットデータが空の時のもの、つまり純粋な送金処理時に呼ばれる。それ以外の　場合にはfallback()が呼び出される。

### DelegateCallとは

delegatecall is a low level function similar to call.

When contract A executes delegatecall to contract B, B's code is executed

with contract A's storage, msg.sender and msg.value.

### Slotとは

solidiyでは32byteを1つの区切りとして認識する。

### mload()とは

引数にした変数の長さを求めるメソッド

### inline assemblyを使う意味

solidityでinline assemblyを使うメリットとして以下が挙げられると思います。  

1. コンパイラの制約を無視した実装ができる
2. ガス代が浮く
3. inline assemblyでしかできない操作を実現できる

### Self Destruct

Contracts can be deleted from the blockchain by calling selfdestruct.   
selfdestruct sends all remaining Ether stored in the contract to a designated address.

### SolidityのSlot

solidityでは、32バイトのデータを1スロットとして考える。

### delegateCallについて

Delegatecallとは、外部コントラクトへの呼び出しに対して呼び出し元のコントラクトの文脈で処理する関数です。ここで言う「コントラクトの文脈」とは、msg.senderやmsg.value、コントラクトのストレージのことなどを指しています。   

delegatecallの場合は外部コントラクトの関数を自身のコントラクトのストレージ文脈で処理することが可能になります。

#### delegateCallを実行する場合の注意事項

1. delegatecall preserves context (storage, caller, etc...)
2. s2torage layout must be the same for the contract calling delegatecall and the contract getting called

#### blockhashとblock.timestampのランダム性

blockhashとblock.timestampはランダム性を確保するための信頼できるソースではありません。

#### tx.originとmsg.senderの違い

msg.senderには、EOAとコントラクトアドレスの2種類が入り得る。tx.originにはEOAしか入らない。  

例えば、アカウントAからコントラクトBを呼び出し、コントラクトBから別のコントラクトCを呼び出したとき、
コントラクトC内でmsg.senderはコントラクトBを指し、tx.originはアカウントAを指す。   

tx.originを使用すると想定とは異なるアドレスが入ってくる可能性(本当はコントラクトのアドレスである必要がある場合)があり、セキュリティ的にリスクがあるため、tx.originの使用は控えた方が良いことになっている。

#### コミットメント方式について

コミットメント方式を使うことでトランザクションの中身を秘密にしたまた送信することができる。

#### block.timestampについて

block.timestampについては、任意に操作できてしまう可能性があるので乱数などの用途には使わないこと。  
強力なマイナーであれば、未来のblock.timestampからスマコンのロジックを読み解いて逆算される可能性があるため。(The Mergeでも発生する？？)

#### スマートコントラクトで署名データを利用する場合

署名ロジックをうまく活用すればメタトランザクションなどの応用に利用できるが、注意しないと脆弱性を突かれる可能性があるのでよく考えて設計する必要がある。  
同じ署名を複数回使用して関数を実行することができるので、署名者の意図が一度の取引を承認することであった場合、有害である可能性が出てくる。  
なので一回きりの署名であることを証明するためにナンスを含める必要がある。ナンスは、通常のトランザクションをsubmitする際に取得できるのでその値を埋め込むこと！

```sol
// コントラクトのアドレス、送信先、総金額、ナンスを含めて署名データを生成するようにする。
keccak256(abi.encodePacked(address(this), _to, _amount, _nonce));
```

#### Vaultとは

DeFiプロトコルで使用される資金用の保管庫のこと。  
ユーザーが入金すると、ある程度の量のシェアがミントされる。DeFiプロトコルは、ユーザーの預金を利用して（何らかの形で）利回りを発生させる。ユーザーは、自分のトークン＋利回りを引き出す。

#### Constant product AMM 

Constant product AMM XY = K

#### Proxyコントラクトとは

ユーザーのトランザクション送信をUpgradableコントラクトへ届ける役割のコントラクトのこと。つまりdelegatecall関数を実行するコントラクトとなる。Proxyコントラクトにはfallback関数にdelegate関数を実装している。この仕組みを上手く利用することでProxyコントラクトに記述されていない関数はfallback関数に定義されている処理を実行する形となる。  

実装例は下記の通り。  
delegatecallの引数の内容は下記の通り

- gas：この呼び出しのために与えるgas量です。gas opcodeは処理のために利用可能なgas量を返します。
- _impl：delegatecall先のコントラクトアドレス
- ptr：上で定義したメモリポインタ。calldataを適用するため。
- calldatasize：msg.data.lengthと同じのデータサイズ
- 0：delegatecall先コントラクトの関数から返される出力データ。現時点ではこのデータは分からないので使わない。
- 0：出力データのサイズ。これ以降、returndetasize opcodeで使用することができる。

```sol
function () payable public {
    address _impl = implementation();
    require(_impl != address(0));
 
    assembly {
      let ptr := mload(0x40)  // フリーメモリポインタ
      calldatacopy(ptr, 0, calldatasize) // calldataをコピーする処理 （msg.data.lengthと同じです）
      let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)  // delegatecall opcodeの操作
      let size := returndatasize
      returndatacopy(ptr, 0, size)
 
      switch result //  成功したら1 失敗したら0が格納される
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
}
```
#### MasterChef Contractとは

Dexにおける流動性提供をしたときに取得できる LP-Token を Stake することで得られる収益を計算するためのスマートコントラクトのこと。

#### unchecked

ガス代を安くする上で使えるのが`unchecked`である。

#### selfdestructとは

コントラクトを壊すメソッド。コントラクトを破棄した呼び出し元にコントラクトが所持していたEtherを全て送金することができる。

#### calldataついて

EVM(Ethereum Virtual Machine)でコードを実行する際にstack、memory、storage、calldata、returndataの５つのデータ領域がある。
calldataはcallまたはdelegatecallで別のコントラクトを呼び出す時に使用するデータ領域で、calldataはbytes型で表される。  

calldataは2つのサブパートに分けることができる。

- メソッドID（4バイト）
- 引数（32バイト）※引数が複数ある場合もある

最終的なcalldataはこの2つを連結させたもの。

##### メソッドIDについて

メソッドIDは、メソッドシグネチャのkecccak256ハッシュの先頭8文字で表される。
メソッドシグネチャは、メソッドの名前とその引数の型のこと。

```bash
例 
メソッドの名前  -->  transferFrom
引数の型  -->  (address, address, uint256)
メソッドシグネチャ  -->  transferFrom(address, address, uint256)
kecccak256ハッシュの先頭8文字  -->  web3.abi.encodeFunctionSignature('transferFrom(address,address,uint256)')  -->  0x4a6e9f4e
0x4a6e9f4eがメソッドIDとなる
```

##### 引数の場合について

calldataの引数部分の求め方

```bash
例
transferFrom(0x0123456789abcdef01223456789abcdef0123456, 0xabcdef0123456789abcdef0123456789abcdef01, 30)

0x0123456789abcdef01223456789abcdef0123456を32バイトにする  -->  0x0000000000000000000000000123456789abcdef01223456789abcdef0123456
0xabcdef0123456789abcdef0123456789abcdef01を32バイトにする  -->  0x000000000000000000000000abcdef0123456789abcdef0123456789abcdef01
30を32バイトにする  -->  0x000000000000000000000000000000000000000000000000000000000000001d
連結する  -->  0x0000000000000000000000000123456789abcdef01223456789abcdef0123456000000000000000000000000abcdef0123456789abcdef0123456789abcdef01000000000000000000000000000000000000000000000000000000000000001d
```

### 参考文献
1. [Solidity by Example](https://solidity-by-example.org/)
2. [Smart Contract Engineer](https://www.smartcontract.engineer/)
3. [Solidity Inline Assembly で気になったことをまとめる](https://blog.suishow.net/2021/08/25/solidity-inline-assembly-%E6%B3%A8%E7%9B%AE%E3%81%99%E3%82%8B%E3%81%A8%E3%81%93%E3%82%8D-%F0%9F%99%83/)
4. [Solidityのストレージスロットとパッキングについて](https://qiita.com/takayukib/items/8647302c4dee028adcca)
5. [Gitpod](https://www.gitpod.io/?utm_source=googleads&utm_medium=search&utm_campaign=dynamic_search_ads&utm_id=16501579379&utm_content=dsa&gclid=CjwKCAiAjs2bBhACEiwALTBWZbtLNbA0yeLyaFjs3dxxuWbfNAhQ16uLrEUuMvx-swM_E4hQRY18yxoCVhIQAvD_BwE)
6. [ChainIDE](https://chainide.com/s/bnbchain/a7a1bba09b194f5b94eb434992121252)
7. [How do I make my DAPP "Serenity-Proof?" ](https://ethereum.stackexchange.com/questions/196/how-do-i-make-my-dapp-serenity-proof)
8. [【Solidity】tx.originとmsg.senderの違い](https://qiita.com/Kumamera/items/a81de80a56340076e254)
9. [forge-std](https://github.com/foundry-rs/forge-std)
10. [foundry-rs/foundry](https://github.com/foundry-rs/foundry)
11. [UniswapV3](https://docs.uniswap.org/contracts/v3/guides/providing-liquidity/setting-up)
12. [Weird ERC20](https://unchain-shiftbase.notion.site/Weird-ERC20-176738db69a14dbaaf189eb85212a28c)
13. [アップグレード可能なスマートコントラクトを実現する具体的なアプローチ](https://zoom-blc.com/how-to-develop-upgradable-contracts)
14. [pancake-farm](https://github.com/pancakeswap/pancake-farm/blob/master/contracts/MasterChef.sol)
15. [【UNCHAIN-dev】openzeppelin-deepdive](https://github.com/unchain-dev/openzeppelin-deepdive/tree/main/bugs)
16. [Foundry book](https://book.getfoundry.sh/projects/project-layout)
17. [BBB 資料](https://unchain-shiftbase.notion.site/Day-1-12-7-833514e490e343098b1df87f85dca1f9)
18. [How to become a smart contract auditor](https://cmichel.io/how-to-become-a-smart-contract-auditor/)
19. [【sherlock】GMX contest ](https://app.sherlock.xyz/audits/contests/6)
20. [【Secureum】Audit Findings 101](https://secureum.substack.com/p/audit-findings-101)
21. [イーサの送金とリエントランシー攻撃](https://nawoo.hateblo.jp/entry/2021/09/19/120558)
22. [Reentrancy | Hack Solidity #1](https://coinsbench.com/reentrancy-hack-solidity-1-aad0154a3a6b)
23. [日本円ハッカソン入門ラボ](https://docs.google.com/presentation/d/e/2PACX-1vRj3P5niG9AYm6Nl6aA0-SAmHgPpZVqYDGrRkkCqJC0a9vcyWCaHyTZSjbZ0LfKfdeimosEStPEJrbz/pub?start=false&loop=false&delayms=3000&slide=id.g11548f0dd74_2_165)
24. [[図解] delegatecall callcode call の違い](https://qiita.com/doskin/items/c4fd8952275c67deb594)
25. [solidityのcalldataの求め方](https://qiita.com/oatnnimi/items/c303667043c90a5252c6)
26. [スマートコントラクトを使った入金システムについて全力で理解してみた](https://tech.bitbank.cc/20201222/)
27. [ERC-20と ERC-721の主な違い](https://info.huobi.co.jp/blog/what-is-erc20-and-erc721/)
28. [第二回コントラクト輪読会レポート〜ERC721のコントラクトを皆で読みながら理解を深めよう〜](https://ethereumnavi.com/2021/11/09/contract-study-2-solidity-erc721/#fn-safemint)
29. [Writing Upgradeable Contracts](https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable)