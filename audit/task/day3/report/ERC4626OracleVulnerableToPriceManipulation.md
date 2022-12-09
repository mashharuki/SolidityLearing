# ERC4626Oracle Vulnerable To Price Manipulation

## 概要

ERC4626 oracle is vulnerable to price manipulation. This allows an attacker to increase or decrease the price to carry out various attacks against the protocol.  

ERC4626のオラクルは、価格操作のロジックに脆弱性を抱えている。これにより、攻撃者は価格を増減させ、プロトコルに対する様々な攻撃を行うことができる。

## 脆弱性の詳細

The `getPrice` function within the `ERC4626Oracle` contract is vulnerable to price manipulation because the price can be increased or decreased within a single transaction/block.  

`ERC4626Oracle` コントラクトの`getPrice`関数では、1ブロック/トランザクション内で価格の増減の操作を行うことができるので、価格を操作させてしまう脆弱性がある。

Based on the `getPrice` function, the price of the LP token of an ERC4626 vault is dependent on the `ERC4626.previewRedeem` and `oracleFacade.getPrice` functions. If the value returns by either `ERC4626.previewRedeem` or `oracleFacade.getPrice` can be manipulated within a single transaction/block, the price of the LP token of an ERC4626 vault is considered to be vulnerable to price manipulation.  

ERC4626のVaultのLPトークンの価格は、`getPrice`関数に基づき、`ERC4626.previewRedeem`関数と`oracleFacade.getPrice`関数に依存します。`ERC4626.previewRedeem`と`oracleFacade.getPrice`のどちらかが返す値が1つのトランザクション/ブロック内で操作できる場合、ERC462vaultのLPトークンの価格は価格操作に対して脆弱性があると考えられます。  

https://github.com/sherlock-audit/2022-08-sentiment-xiaoming9090/blob/99afd59bb84307486914783be4477e5e416510e9/oracle/src/erc4626/ERC4626Oracle.sol#L8

```solidity
File: ERC4626Oracle.sol
35:     function getPrice(address token) external view returns (uint) {
36:         uint decimals = IERC4626(token).decimals();
37:         return IERC4626(token).previewRedeem(
38:             10 ** decimals
39:         ).mulDivDown(
40:             oracleFacade.getPrice(IERC4626(token).asset()),
41:             10 ** decimals
42:         );
43:     }
```

It was observed that the `ERC4626.previewRedeem` couldbe manipulated within a single transaction/block. As shown below, the `previewRedeem` function will call the `convertToAssets` function. Within the `convertToAssets`, the number of assets per share is calculated based on the current/spot total assets and current/spot supply that can be increased or decreased within a single block/transaction by calling the vault's deposit, mint, withdraw or redeem functions. This allows the attacker to artificially inflate or deflate the price within a single block/transaction.  

`ERC4626.previewRedeem` は、1つのトランザクション/ブロック内で操作できることが確認されました。以下に示すように、`previewRedeem`関数は`convertToAssets`関数を呼び出します。`convertToAssets` 内では、1トークンあたりの資産数が現在/スポットの総資産と現在/スポットの供給量に基づいて計算され、金庫のdeposit、ミント、引き出し、換金関数を呼び出すことで1ブロック/トランザクション内で増減させることができるようになっています。これにより、攻撃者は単一のブロック/取引内で価格を人為的に上昇させたり、下降させたりすることができます。

https://github.com/sherlock-audit/2022-08-sentiment-xiaoming9090/blob/99afd59bb84307486914783be4477e5e416510e9/protocol/src/tokens/utils/ERC4626.sol#L154

```solidity
File: ERC4626.sol
154:     function previewRedeem(uint256 shares) public view virtual returns (uint256) {
155:         return convertToAssets(shares);
156:     }
```

https://github.com/sherlock-audit/2022-08-sentiment-xiaoming9090/blob/99afd59bb84307486914783be4477e5e416510e9/protocol/src/tokens/utils/ERC4626.sol#L132

```solidity
File: ERC4626.sol
132:     function convertToAssets(uint256 shares) public view virtual returns (uint256) {
133:         uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.
134: 
135:         return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
136:     }
```

## 影響

The attacker could perform price manipulation to make the apparent value of an asset to be much higher or much lower than the true value of the asset. Following are some risks of price manipulation:  

攻撃者は価格操作を行い、トークンの価値を高く見せたり低く見せたりすることができます。価格操作のリスクとしては、以下のようなものがあります。

- An attacker can increase the value of their collaterals to increase their borrowing power so that they can borrow more assets than they are allowed from Sentiment.
- An attacker can decrease the value of some collaterals and attempt to liquidate another user account prematurely.

- 攻撃者は、Sentimentから許可された以上の資産を借りることができるように、彼らの借入力を増加させるために彼らの担保の価値を増加させることができます。
- 攻撃者は、いくつかの担保の価値を下げ、他のユーザー・アカウントを早期に清算しようとすることができます。

## 推奨対処法　

Avoid using `previewRedeem` function to calculate the price of the LP token of an ERC4626 vault. Consider implementing TWAP so that the price cannot be inflated or deflated within a single block/transaction or within a short period of time.

ERC4626準拠のLPトークンの価格計算に`previewRedeem` 関数を利用することを避けること。  
1ブロック/トランザクション内や短時間での価格の膨張・収縮ができないような時間加重平均価格の算出ロジックの実装を検討する。
