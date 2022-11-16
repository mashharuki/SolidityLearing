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

引数にした変数の長さをも求めるメソッド

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

#### delegateCallを実行する場合の注意事項

1. delegatecall preserves context (storage, caller, etc...)
2. s2torage layout must be the same for the contract calling delegatecall and the contract getting called

#### blockhashとblock.timestampのランダム性

blockhashとblock.timestampはランダム性を確保するための信頼できるソースではありません。

### 参考文献
1. [Solidity by Example](https://solidity-by-example.org/)
2. [Smart Contract Engineer](https://www.smartcontract.engineer/)
3. [Solidity Inline Assembly で気になったことをまとめる](https://blog.suishow.net/2021/08/25/solidity-inline-assembly-%E6%B3%A8%E7%9B%AE%E3%81%99%E3%82%8B%E3%81%A8%E3%81%93%E3%82%8D-%F0%9F%99%83/)
4. [Solidityのストレージスロットとパッキングについて](https://qiita.com/takayukib/items/8647302c4dee028adcca)
5. [Gitpod](https://www.gitpod.io/?utm_source=googleads&utm_medium=search&utm_campaign=dynamic_search_ads&utm_id=16501579379&utm_content=dsa&gclid=CjwKCAiAjs2bBhACEiwALTBWZbtLNbA0yeLyaFjs3dxxuWbfNAhQ16uLrEUuMvx-swM_E4hQRY18yxoCVhIQAvD_BwE)
6. [ChainIDE](https://chainide.com/s/bnbchain/a7a1bba09b194f5b94eb434992121252)