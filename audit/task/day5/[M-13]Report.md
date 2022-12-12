## [M-13] 悪意のあるメーカーが注文期間を0に設定することができる脆弱性

### ■ カテゴリー

Insuffisient check

### ■ 条件

最小注文期間を0に設定された場合

### ■ ハッキングの詳細

悪意のあるメーカーは、最小注文期間を0に設定することができ、これは注文が成立した後、即座に失効することを意味します。買い手は引出しオプションのみを取得し、それも権利行使価格の手数料がかかるため、買い手はこの無意味な取引で損をすることを余儀なくされます。

### ■ 修正方法

最小注文期間が一定の長さ以上になるような条件文を加えること。