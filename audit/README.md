# Audit

### スマートコントラクト監査用のプラットフォーム

<aside>
🕵️‍♂️ 各プラットフォームについて

🥚: Code4rena 👉 初心者 + 初めて報酬をもらってみたい方

🐣: Sherlock 👉 C4で3つ以上、MediumかHighのバグを発見した方

🐔: Immunefi 👉 3つ以上、HighのSolo Findingをした方
</aside>

### Tips

1. 最も発行されているERC20トークンのTop3は？
2. `transfer` と`transferFrom` の違いは？
3. allowanceがないと使えない関数とその理由は？
4. ERC20にはなかったERC721の関数は？
5. ERC20とERC721のtransferの違いはなんでしょうか？
6. なぜその違いが起こるのでしょうか？
7. OpenZeppelin#ERC721の `_checkOnERC721Received` はどこで使われているでしょう か？
8. OpenZeppelin#ERC721の _checkOnERC721Received はどこで使われているでしょう か？
9. なぜNFTを送信するsuperSafeTransferFrom は失敗したのでしょうか？
10. _checkOnERC721Receive を使用する目的はなんでしょうか？
11. Upgradable Contractの仕組みを絵にしよう！
12. MasterChef どのような目的で使用されるのか？

### example 1USDC = 150 JPYC

X: (JPYC) 15000 → 14285 (15000 - 14285 = 715) 715 / 5 = 143  

Y: (USDC) 100 → 105  

K = XY = 1510^5  
  
5 USDCを交換したい!!!  

Kをずっと一定にしたい!!!!  

y = k * 1/x  

y = 15*10^5 / 105 = 14285  

### レポートを読む上での注意点

- 過去のレポートを読むこと
- DEXのプロダクトだからといって同じようなバグが連発する訳ではない・・
- 上にあるほどわかりやすいレポート(わからなかったら他の人のレポートに目を通すこと)
- レポートを読む頻度は、技術を新しくキャッチアップする頻度と同じぐらい。
- パターンというストックを増やすことがレポートに目を通す一番の目的
- パターンで見つけられるものとプロジェクト固有のもので分別すること
- 思い出すきっかけを作ること

### 参考資料
1. [レポートの例](https://code4rena.com/reports/2022-03-sublime/)
2. [レポートの例2](https://hackmd.io/@Tomo0930/SkCXCHvvj)
3. [参考になるレポート例](https://github.com/code-423n4/2022-01-sandclock-findings/issues/157)