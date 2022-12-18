# Audit report(mashhrauki)

## [H-1] There is a risk of DoS due to the lack of a maximum value that can be set for `tokenIds`, which prevents users' assets from being traded properly.

## Summary 

infinite loops may occur in `wrap()` and `unwrap()` processes because there is no upper limit on `tokenIds`.

## Vulnerability Detail 

There are several loop processes using `tokenIds.length`, but since no upper limit is set, an infinite loop may occur and the `wrap()` and `unwrap()` methods may not be executed. For example, if an NFT contract address with 100,000 tokens issued is set as a pair.

## Impact 

Although `tokenIds.length` is used in `wrap()`, `unwrap()`, and `_validateTokenIds()`, no upper limit is set, so if an NFT contract with countless tokens issued is set, an infinite loop will occur and the contract's There is a risk that the wrap and unwrap functions will not function, and the asset will not be controlled properly.

## Code Snippet

https://github.com/code-423n4/2022-12-caviar/blob/main/src/Pair.sol#L238   

https://github.com/code-423n4/2022-12-caviar/blob/main/src/Pair.sol#L258  

https://github.com/code-423n4/2022-12-caviar/blob/main/src/Pair.sol#L468  


## Tool used 
nothing

## Recommendation 

The following measures should be applied.

1. Sets the maximum number of tokens that can be set.
2. Ensure that the number of tokens in the NFT has not reached the upper limit when registering a token pair.

**before**

```solidity
    function wrap(uint256[] calldata tokenIds, bytes32[][] calldata proofs)
        public
        returns (uint256 fractionalTokenAmount)
    {
        // *** Checks *** //

        // check that wrapping is not closed
        require(closeTimestamp == 0, "Wrap: closed");

        // check the tokens exist in the merkle root
        _validateTokenIds(tokenIds, proofs);
```

**after**

```diff
+   uint const UPPER_TOKENS = 10000; 

    SHIP.....

    function wrap(uint256[] calldata tokenIds, bytes32[][] calldata proofs)
        public
        returns (uint256 fractionalTokenAmount)
    {

        // *** Checks *** //

+       // check the tokens length
+       require(tokenIds.length >= UPPER_TOKENS, "tokens.length is too much!!")

        // check that wrapping is not closed
        require(closeTimestamp == 0, "Wrap: closed");

        // check the tokens exist in the merkle root
        _validateTokenIds(tokenIds, proofs);
```

## [M-1]  There is a risk that overflow will occur and the price of the fractional token will not be appropriate.

## Summary 

`Pair` contract use `_baseTokenReserves()` to calculate the price of fractional tokens, but there is a possibility of `reverts` due to loose checking of the variable logic.

## Vulnerability Detail 

In `_baseTokenReserves()`, the value of `the current base token reserves` is obtained, but when returning the value in the case of `ETH`, the `msg.value` is subtracted from the contract balance. However, the logic to check if the contract balance is greater than `msg.value` before this subtraction is missing, so `reverts` may occur and the value may not be returned properly.

## Impact

The value of `the current base token reserves` will not be available, so if the appropriate `msg.value` is not set when the `baseToken` is ETH, the buyQuote()`, `sellQuote()`, `addQuote()`, ` removeQuote()` and other methods will not be processed properly.

## Code Snippet

https://github.com/code-423n4/2022-12-caviar/blob/main/src/Pair.sol#L479  

## Tool used 
nothing

## Recommendation 

The following measures should be applied.

- Adding a check logic that `address(this).balance >= msg.value`.

**before**

```sol
function _baseTokenReserves() internal view returns (uint256) {
    return baseToken == address(0)
        ? address(this).balance - msg.value // subtract the msg.value if the base token is ETH
        : ERC20(baseToken).balanceOf(address(this));
}
```

**after**

```diff
function _baseTokenReserves() internal view returns (uint256) {
+   if(baseToken == address(0)) {
+       require(address(this).balance >= msg.value, "address(this).balance must be bigger than msg.value");
+   } 

    return baseToken == address(0)
        ? address(this).balance - msg.value // subtract the msg.value if the base token is ETH
        : ERC20(baseToken).balanceOf(address(this));
}
```

## [M-2] There is a risk of overflow and manipulation of the balance of the `fractional token` held by the contract.

## Summary 

The `_transferFrom()` method is used to update the balance of the `factional Token`, but there is a risk of overflow and manipulation of the sender's balance due to a check being omitted when updating the balance of the source address.

## Vulnerability Detail 

The `_transferFrom()` method is called in the `buy()` and `sell()` methods to update the balance of the `factional Token`, but there is a risk of overflow and manipulation of the sender's balance due to a check being omitted when updating the balance of the source address.

## Impact 

There is a risk that overflow occurs when updating the balance of the sender's address and the price of the paired NFT is intentionally lowered.

## Code Snippet

https://github.com/code-423n4/2022-12-caviar/blob/main/src/Pair.sol#L448 

## Tool used 
nothing

## Recommendation 

The following measures should be applied.

- Adding a check logic that `balanceOf[from] >= amount`.

**before**

```solidity
function _transferFrom(address from, address to, uint256 amount) internal returns (bool) {
    balanceOf[from] -= amount;
```

**after**

```diff
function _transferFrom(address from, address to, uint256 amount) internal returns (bool) {
+   require(balanceOf[from] >= amount, "balanceOf[from] must be bigger than amount.");
    balanceOf[from] -= amount;
```

## [M-3] a user can create a pair with an NFT that does not support ERC721 (like CryptoPunk), and a user cannot wrap and unwrap

## Summary 

Users can also register NFT addresses that do not conform to ERC721, such as　CryptoPunk, but there is a risk that they will not be able to perform `wrap` and `unwrap` processing because of errors in the `safeTransferFrom()` call.

## Vulnerability Detail 

When a pair is created and `wrap` or `unwrap` processing is performed, the `safeTransferFrom()` supported by ERC721 is supposed to be called, but there is a risk that well-known NFT contract addresses that do not support ERC721, such as CryptoPunk, may be registered and the function will not process properly.

## Impact 

Since the pair itself can be created, it is a middle risk because users will not be able to wrap or unwrap the NFT because an error will occur when they try to use the contract's functions.

## Code Snippet

https://github.com/code-423n4/2022-12-caviar/blob/main/src/Pair.sol#L239   

https://github.com/code-423n4/2022-12-caviar/blob/main/src/Pair.sol#L259

## Tool used 
nothing

## Recommendation 

Pair countract uses solmate’s ERC721.safeTransferFrom which requires that the NFT contract implements onERC721Received. For the case of OG NFTs like punks and rocks, this will fail, https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol#L120

## [Informational Findings-1] typo

There is a typo in `_validateTokenIds()` method

## Code Snippet

https://github.com/code-423n4/2022-12-caviar/blob/0212f9dc3b6a418803dbfacda0e340e059b8aae2/src/Pair.sol#L465

## Recommendation 

Recommend to fix to `bytes32(0)`.

