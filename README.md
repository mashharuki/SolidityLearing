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


### 参考文献
1. [Solidity by Example](https://solidity-by-example.org/)
2. [Smart Contract Engineer](https://www.smartcontract.engineer/)