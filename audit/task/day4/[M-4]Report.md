## [M-4] requiredImprovementRateが、previousInterestRateが10未満の場合、精度低下のため期待通りに動作しない可能性がある脆弱性

### ■ カテゴリー

ミドルリスク

### ■ 条件

previousInterestRateが10未満でrequiredImprovementRateを100に指定した場合

### ■ ハッキングの詳細

```solidity
{
    uint256 previousInterestRate = loan.perAnumInterestRate;
    uint256 previousDurationSeconds = loan.durationSeconds;
    require(interestRate <= previousInterestRate, 'NFTLoanFacilitator: rate too high');
    require(durationSeconds >= previousDurationSeconds, 'NFTLoanFacilitator: duration too low');
    require((previousLoanAmount * requiredImprovementRate / SCALAR) <= amountIncrease
    || previousDurationSeconds + (previousDurationSeconds * requiredImprovementRate / SCALAR) <= durationSeconds 
    || (previousInterestRate != 0 // do not allow rate improvement if rate already 0
        && previousInterestRate - (previousInterestRate * requiredImprovementRate / SCALAR) >= interestRate), 
    "NFTLoanFacilitator: proposed terms must be better than existing terms");
}
```

previousInterestRateが10未満でrequiredImprovementRateが100の場合、精度低下のため、新しいinterestRateは前のものと同じでよいとしている。

### ■ 修正方法

requireの条件文に、Openzeppelinなどから提供されているMathライブラリを使用すること。