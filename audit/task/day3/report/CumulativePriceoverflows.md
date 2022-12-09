# _updateTwav() and _getTwav() will revert when cumulativePrice overflows

## コードの詳細

https://github.com/code-423n4/2022-06-nibbl/blob/8c3dbd6adf350f35c58b31723d42117765644110/contracts/Twav/Twav.sol#L28
https://github.com/code-423n4/2022-06-nibbl/blob/8c3dbd6adf350f35c58b31723d42117765644110/contracts/Twav/Twav.sol#L40

## 脆弱性の詳細

### 脆弱性の影響

Contract will break when cumulativeValuation overflows.  

累積評価額がオーバーフローした場合、契約は破棄されます。

### PoC (例)

Cumulative prices are designed to work with overflows/underflows because in the end the difference is important.  

In _updateTwav() when _prevCumulativeValuation + (_valuation *_timeElapsed) overflows the contract will not work anymore.  

累積価格はオーバーフロー/アンダーフローで動作するように設計されており、最終的にはその差が重要だからです。  

updateTwav() において、_prevCumulativeValuation + (_valuation *_timeElapsed) がオーバーフローした場合、契約はもう機能しなくなります。  

```sol
//add the previous observation to make it cumulative @audit overflow breaks the contract
twavObservations[twavObservationsIndex] = TwavObservation(_blockTimestamp, _prevCumulativeValuation + (_valuation * _timeElapsed)); 
```

Same problem in _getTwav()  

同じ問題は、_getTwav()関数内にもあります。

```sol
  _twav = (_twavObservationCurrent.cumulativeValuation - _twavObservationPrev.cumulativeValuation) / (_twavObservationCurrent.timestamp - _twavObservationPrev.timestamp);@audit same overflow breaks the contract

}
```

### 似たような事例

https://github.com/code-423n4/2022-04-phuture-findings/issues/62

### 推奨対策

Add unchecked keyword in every line you add / subtract cumulative prices.

累積価格の加算/減算を行う行ごとに、`unchecked`を追加します。