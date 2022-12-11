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