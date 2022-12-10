# Backed Protocol contest Findings & Analysis Report

## Summary

## Severity Criteria
C4は、OWASPの標準に基づいた手法により、開示された脆弱性の深刻度を評価します。  

脆弱性は、高、中、低/非重要の3つの主要なリスクカテゴリーに分類されます。  

脆弱性の評価を行う際のハイレベルな検討事項は、以下の主要分野にわたります。  

- 悪意のある入力の処理
- 特権のエスカレーション
- 演算処理
- ガスの使用

提出された評価プロセスを通じて参照される重要度基準に関する詳細な情報は、C4ウェブサイト上で提供されるドキュメントを参照してください。

### ハイリスクの脆弱性

- [H-01] Can force borrower to pay huge interest
- [H-02] currentLoanOwner can manipulate loanInfo when any lenders try to buyout
- [H-03] Borrower can be their own lender and steal funds from buyout due to reentrancy

- [H-01] 借主に多額の利息を支払わせることができる。
- [H-02] どのレンダーもバイアウトしようとすると、currentLoanOwnerがloanInfoを操作することができる。
- [H-03] 借り手が自分自身の貸し手となり、reentrancyのためにバイアウトから資金を盗むことができる。

### ミドルリスクの脆弱性

- [M-01] When an attacker lends to a loan, the attacker can trigger DoS that any lenders can not buyout it
- [M-02] Protocol doesn’t handle fee on transfer tokens
- [M-03] sendCollateralTo is unchecked in closeLoan(), which can cause user’s collateral NFT to be frozen
- [M-04] requiredImprovementRate can not work as expected when previousInterestRate less than 10 due to precision loss
- [M-05] Borrowers lose funds if they call repayAndCloseLoan instead of closeLoan
- [M-06] Might not get desired min loan amount if _originationFeeRate changes
- [M-07] mintBorrowTicketTo can be a contract with no onERC721Received method, which may cause the BorrowTicket NFT to be frozen and put users’ funds at risk

- [M-01] 攻撃者がローンを貸した場合、貸した人が買い取れないようなDoSを発生させることができる。
- [M-02] 転送トークンの手数料を扱わないプロトコル
- [M-03] closeLoan()でsendCollateralToがチェックされていないため、ユーザの担保NFTが凍結される可能性がある。
- [M-04] requiredImprovementRateが、previousInterestRateが10未満の場合、精度低下のため期待通りに動作しないことがある。
- [M-05] 借入人がcloseLoanではなくrepayAndCloseLoanを呼び出すと資金を失う。
- [M-06] _originationFeeRateが変更された場合、希望の最小融資額が得られない場合がある。
- [M-07] mintBorrowTicketToはonERC721Receivedメソッドを持たない契約である可能性があり、これによりBorrowTicket NFTが凍結され、ユーザーの資金が危険にさらされる可能性があります。

### ローリスクの脆弱性

- [L-01] Loans can be created and paid with non-existent/destructed tokens
- [L-02] originationFeeRates of less than 1000 may charge no fees if amounts are small
- [L-03] A malicious owner can keep the fee rate at zero, but if a large value transfer enters the mempool, the owner can jack the rate up to the maximum
- [L-04] A malicious owner can set an effectively infinite improvement rate with type(uint256).max after he/she has entered into a loan to prevent others from buying them out
- [L-05] tokenURI() reverts for tokens that don’t implement IERC20Metadata
- [L-06] _safeMint() should be used rather than _mint() wherever possible
- [L-07] loanFacilitatorTransfer() does not verify that the receiver is capable of handling an NFT
- [L-08] Missing checks for address(0x0) when assigning values to address state variables
- [N-01] constants should be defined rather than using magic numbers
- [N-02] Typos
- [N-03] NatSpec is incomplete
- [N-04] Event is missing indexed fields

- [L-01] 存在しない/破壊されたトークンでローンを作成し、支払うことができるようになりました。
- [L-02] originationFeeRatesが1000未満の場合、金額が小さいと手数料が無料になることがある
- [L-03] 悪意のあるオーナーは手数料をゼロに保つことができるが、大きな金額の送金がメンプールに入ると、オーナーは手数料を最大にすることができる。
- [L-04] 悪意のあるオーナーは、ローンを組んだ後にtype(uint256).maxで事実上無限の改善レートを設定し、他の人に買い取られないようにできる
- [L-05] IERC20Metadata を実装していないトークンのために tokenURI() が元に戻る
- [L-06] 可能な限り_mint()よりも_safeMint()が使用されるべきである
- [L-07] loanFacilitatorTransfer()は受信者がNFTを処理する能力があることを検証しない
- [L-08] アドレスステート変数に値を割り当てる際のaddress(0x0)のチェックが欠落しています。
- [N-01] 定数はマジックナンバーを使用するのではなく、定義されるべきです。
- [N-02] 誤字脱字
- [N-03] NatSpecが不完全である
- [N-04] イベントにはインデックス付きのフィールドがない