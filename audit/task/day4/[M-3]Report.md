## [M-3] closeLoan()でsendCollateralToがERC721対応のコントラクトアドレスがどうかチェックされていないため、ユーザの担保NFTが凍結される脆弱性

### ■ カテゴリー

ERC721

### ■ 条件

`IERC721(loan.collateralContractAddress).transferFrom`によってNFTを移転させる先のアドレスにIERC721に準拠していないアドレスが割り当てられていた場合。

### ■ ハッキングの詳細

```sol
function closeLoan(uint256 loanId, address sendCollateralTo) external override notClosed(loanId) {
    require(IERC721(borrowTicketContract).ownerOf(loanId) == msg.sender,
    "NFTLoanFacilitator: borrow ticket holder only");
    Loan storage loan = loanInfo[loanId];
    require(loan.lastAccumulatedTimestamp == 0, "NFTLoanFacilitator: has lender, use repayAndCloseLoan");
    
    loan.closed = true;
    IERC721(loan.collateralContractAddress).transferFrom(address(this), sendCollateralTo, loan.collateralTokenId);
    emit Close(loanId);
}
```

`sendCollateralTo` は、`closeLoan()`が呼ばれたときに担保 NFT を受け取ります。ただし、`sendCollateralTo` が ERC721 をサポートしないコントラクトのアドレスである場合、担保 NFT をコントラクト内で凍結されてしまう。

### ■ 修正方法

`transfrom`メソッドではなく、`safeTransferFrom`メソッドを使用するように修正する。

```sol
function closeLoan(uint256 loanId, address sendCollateralTo) external override notClosed(loanId) {
    require(IERC721(borrowTicketContract).ownerOf(loanId) == msg.sender,
    "NFTLoanFacilitator: borrow ticket holder only");
    Loan storage loan = loanInfo[loanId];
    require(loan.lastAccumulatedTimestamp == 0, "NFTLoanFacilitator: has lender, use repayAndCloseLoan");
    
    loan.closed = true;
    IERC721(loan.collateralContractAddress).safeTransferFrom(address(this), sendCollateralTo, loan.collateralTokenId);
    emit Close(loanId);
}
```