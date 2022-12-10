## [M-6] _originationFeeRateが変更された場合、希望の最小融資額が得られない場合がある脆弱性

### ■ カテゴリー

ミドルリスク

### ■ 条件

`createLoan`して借り手が発生した後に、ownerが`updateOriginationFeeRate`メソッドを呼び出してFeeを更新した場合

### ■ ハッキングの詳細

```sol
originationFeeRate = _originationFeeRate;
```

管理者は updateOriginationFeeRate を呼び出すことで、オリジネーション手数料を更新することができます。借り手は createLoan で設定された minLoanAmount を受け取らず、 (1 - originationFee) * minLoanAmount しか受け取らないことに注意してください (「貸出」参照)。したがって、彼らは実際に受け取る手数料後の金額に到達するために、現在のオリジネーション手数料を使用してminLoanAmountを事前に計算する必要があります。管理者が手数料を増額した場合、借り手は家賃を賄うために必要な資金よりも少ない資金しか受け取れず、ホームレスになる可能性があります。

### ■ 修正方法

minLoanAmountを手数料適用前ではなく手数料適用後の料金とする形に再考すること。