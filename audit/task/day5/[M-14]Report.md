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